//
//  TOFileAttributes.m
//  TOFileAttributesExample
//
//  Created by Tim Oliver on 20/5/21.
//

#import "TOFileAttributes.h"
#import <sys/xattr.h>

NSErrorDomain const TOFileAttributesErrorDomain = @"TOFileAttributesErrorDomain";

// -----------------------------------------------------

@interface TOFileAttributes ()

// Shared cache for all instances
@property (nonatomic, class, readonly) NSCache *sharedCache;

// Writable copy of the provided URL
@property (nonatomic, strong, readwrite) NSURL *fileURL;

// Local cache for accessed properties
@property (nonatomic, strong) NSCache *cache;

// An error, if any, that occurred from the last read/write operation.
@property (nonatomic, strong, readwrite) NSError *latestError;

@end

// -----------------------------------------------------

@implementation TOFileAttributes

#pragma mark - Object Creation -

+ (instancetype)attributesWithFileURL:(NSURL *)fileURL
{
    // Try and return a cached version if it's available
    NSCache *cache = [TOFileAttributes sharedCache];
    NSString *cacheKey = [[self class] cacheKeyForURL:fileURL];
    id attributes = [cache objectForKey:cacheKey];
    if (attributes) { return attributes; }

    // Make a new instance and store it to cache
    attributes = [[[self class] alloc] initWithFileURL:fileURL];
    [cache setObject:attributes forKey:cacheKey];
    return attributes;
}

- (instancetype)initWithFileURL:(NSURL *)fileURL
{
    return [self initWithFileURL:fileURL cached:YES];
}

- (instancetype)initWithFileURL:(NSURL *)fileURL cached:(BOOL)cached
{
    if (self = [super init]) {
        _fileURL = fileURL;

        // Create the local cache for this object
        if (cached) {
            self.cache = [[NSCache alloc] init];
        }

        // Force it to load its default value
        self.identifierPrefix = nil;
    }

    return self;
}

#pragma mark - Shared Cache -

+ (NSCache *)sharedCache
{
    static dispatch_once_t onceToken;
    static NSCache *cache;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
    });
    return cache;
}

+ (NSString *)cacheKeyForURL:(NSURL *)url
{
    // Generate a unique key that could be used to store
    // this file URL and class combination in the cache
    NSString *className = NSStringFromClass(self.class);
    return [NSString stringWithFormat:@"%@.%lul",
            className, (unsigned long)url.hash];
}

#pragma mark - Property Accessor Implementation -

- (nullable id)valueForProperty:(NSString *)propertyName
                           type:(TOPropertyAccessorDataType)type
                    objectClass:(nullable Class)objectClass
{
    // Return the cached property if it's available
    id cachedProperty = [self.cache objectForKey:propertyName];
    if (cachedProperty != nil) { return cachedProperty; }

    // Convert all the properties to C strings
    const char *attributeName = [[self attributeNameForProperty:propertyName]
                                 cStringUsingEncoding:NSUTF8StringEncoding];
    const char *filePath = [self.fileURL.path cStringUsingEncoding:NSUTF8StringEncoding];

    id value = nil;
    BOOL success = NO;
    switch (type) {
        case TOPropertyAccessorDataTypeInt: value = intValue(filePath, attributeName, &success); break;
        case TOPropertyAccessorDataTypeUnsignedInt: value = unsignedIntValue(filePath, attributeName, &success); break;
        case TOPropertyAccessorDataTypeFloat: value = floatValue(filePath, attributeName, &success); break;
        case TOPropertyAccessorDataTypeBool: value = boolValue(filePath, attributeName, &success); break;
        case TOPropertyAccessorDataTypeDate: value = dateValue(filePath, attributeName, &success); break;
        case TOPropertyAccessorDataTypeString: value = stringValue(filePath, attributeName, &success); break;
        case TOPropertyAccessorDataTypeData: value = dataValue(filePath, attributeName, &success); break;
        case TOPropertyAccessorDataTypeObject: value = objectValue(filePath, attributeName, objectClass,
                                                                   &success);  break;
        case TOPropertyAccessorDataTypeArray: value = (NSArray *)objectValue(filePath, attributeName,
                                                                             objectClass, &success); break;
        case TOPropertyAccessorDataTypeDictionary: value = (NSDictionary *)objectValue(filePath, attributeName,
                                                                                       objectClass, &success); break;
        default: break;
    }

    // Save to cache if successful
    if (success) {
        [self.cache setObject:value forKey:propertyName];
        self.latestError = nil;
    } else {
        // If unsuccessful, delete the version from the cache and catch the error
        [self.cache removeObjectForKey:propertyName];
        self.latestError = [self captureLatestError];
    }

    return value;
}

- (void)setValue:(_Nullable id)value
     forProperty:(NSString *)propertyName
            type:(TOPropertyAccessorDataType)type
{
    const char *attributeName = [[self attributeNameForProperty:propertyName]
                                 cStringUsingEncoding:NSUTF8StringEncoding];
    const char *filePath = [self.fileURL.path cStringUsingEncoding:NSUTF8StringEncoding];

    BOOL success = NO;
    switch (type) {
        case TOPropertyAccessorDataTypeInt: success = setIntValue(filePath, attributeName, value); break;
        case TOPropertyAccessorDataTypeUnsignedInt: success = setUnsignedIntValue(filePath, attributeName, value); break;
        case TOPropertyAccessorDataTypeFloat: success = setFloatValue(filePath, attributeName, value); break;
        case TOPropertyAccessorDataTypeBool: success = setBoolValue(filePath, attributeName, value); break;
        case TOPropertyAccessorDataTypeDate: success = setDateValue(filePath, attributeName, value); break;
        case TOPropertyAccessorDataTypeString: success = setStringValue(filePath, attributeName, value); break;
        case TOPropertyAccessorDataTypeData: success = setDataValue(filePath, attributeName, value); break;
        case TOPropertyAccessorDataTypeObject: success = setObjectValue(filePath, attributeName, value); break;
        case TOPropertyAccessorDataTypeArray: success = setObjectValue(filePath, attributeName, value);  break;
        case TOPropertyAccessorDataTypeDictionary: success = setObjectValue(filePath, attributeName, value); break;
        default: break;
    }

    // Update the cache with the new value
    if (success) {
        [self.cache setObject:value forKey:propertyName];
        self.latestError = nil;
    } else {
        // Delete the now invalid value from the cache
        // and set the public error flag
        [self.cache removeObjectForKey:propertyName];
        self.latestError = [self latestError];
    }
}

#pragma mark - File Attribute Setters -
static inline BOOL setIntValue(const char *filePath, const char *attributeName, id value)
{
    long integerValue = [(NSNumber *)value longValue];
    int result = setxattr(filePath, attributeName, &integerValue, sizeof(long), 0, 0);
    return (result >= 0);
}

static inline BOOL setUnsignedIntValue(const char *filePath, const char *attributeName, id value)
{
    unsigned long integerValue = [(NSNumber *)value unsignedLongValue];
    int result = setxattr(filePath, attributeName, &integerValue, sizeof(unsigned long), 0, 0);
    return (result >= 0);
}

static inline BOOL setFloatValue(const char *filePath, const char *attributeName, id value)
{
    double doubleValue = [(NSNumber *)value doubleValue];
    int result = setxattr(filePath, attributeName, &doubleValue, sizeof(double), 0, 0);
    return (result >= 0);
}

static inline BOOL setBoolValue(const char *filePath, const char *attributeName, id value)
{
    BOOL boolValue = [(NSNumber *)value boolValue];
    int result = setxattr(filePath, attributeName, &boolValue, sizeof(BOOL), 0, 0);
    return (result >= 0);
}

static inline BOOL setDateValue(const char *filePath, const char *attributeName, id value)
{
    NSTimeInterval timeValue = [(NSDate *)value timeIntervalSince1970];
    int result = setxattr(filePath, attributeName, &timeValue, sizeof(NSTimeInterval), 0, 0);
    return (result >= 0);
}

static inline BOOL setStringValue(const char *filePath, const char *attributeName, id value)
{
    const char *stringValue = [(NSString *)value UTF8String];
    int result = setxattr(filePath, attributeName, &stringValue, strlen(stringValue), 0, 0);
    return (result >= 0);
}

static inline BOOL setDataValue(const char *filePath, const char *attributeName, id value)
{
    const void *dataValue = [(NSData *)value bytes];
    size_t size = [(NSData *)value length];
    int result = setxattr(filePath, attributeName, &dataValue, size, 0, 0);
    return (result >= 0);
}

static inline BOOL setObjectValue(const char *filePath, const char *attributeName, id value)
{
    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value
                                         requiringSecureCoding:YES
                                                         error:&error];
    if (error) {
        errno = EIO;
        NSLog(@"TOFileAttributes: Unable to encode data: '%@'", error.localizedDescription);
        return NO;
    }

    int result = setxattr(filePath, attributeName, data.bytes, data.length, 0, 0);
    return (result >= 0);
}

#pragma mark - File Attribute Getters -

static inline NSNumber *intValue(const char *filePath, const char *attributeName, BOOL *success)
{
    long integerValue = 0;
    ssize_t result = getxattr(filePath, attributeName, &integerValue, sizeof(long), 0, 0);
    *success = (result >= 0);
    return @(integerValue);
}

static inline NSNumber *unsignedIntValue(const char *filePath, const char *attributeName, BOOL *success)
{
    unsigned long integerValue = 0;
    ssize_t result = getxattr(filePath, attributeName, &integerValue, sizeof(unsigned long), 0, 0);
    *success = (result >= 0);
    return @(integerValue);
}

static inline NSNumber *floatValue(const char *filePath, const char *attributeName, BOOL *success)
{
    double floatValue = 0;
    ssize_t result = getxattr(filePath, attributeName, &floatValue, sizeof(double), 0, 0);
    *success = (result >= 0);
    return @(floatValue);
}

static inline NSNumber *boolValue(const char *filePath, const char *attributeName, BOOL *success)
{
    BOOL boolValue = 0;
    ssize_t result = getxattr(filePath, attributeName, &boolValue, sizeof(BOOL), 0, 0);
    *success = (result >= 0);
    return @(boolValue);
}

static inline NSDate *dateValue(const char *filePath, const char *attributeName, BOOL *success)
{
    NSTimeInterval timeValue = 0;
    ssize_t result = getxattr(filePath, attributeName, &timeValue, sizeof(NSTimeInterval), 0, 0);
    *success = (result >= 0);
    return [NSDate dateWithTimeIntervalSince1970:timeValue];
}

static inline NSString *stringValue(const char *filePath, const char *attributeName, BOOL *success)
{
    // Work out how much memory we need to allocate to load this string
    size_t bufferLength = getxattr(filePath, attributeName, NULL, 0, 0, 0);
    if (bufferLength <= 0) { return nil; }

    // Allocate memory for the buffer and convert it to NSString
    char *buffer = malloc(bufferLength);
    *success = getxattr(filePath, attributeName, buffer, bufferLength, 0, 0) >= 0;
    NSString *stringValue = [[NSString alloc] initWithBytes:buffer
                                                     length:bufferLength
                                                   encoding:NSUTF8StringEncoding];
    free(buffer);

    return stringValue;
}

static inline NSData *dataValue(const char *filePath, const char *attributeName, BOOL *success)
{
    // Work out how much memory we need to allocate to load this data
    size_t bufferLength = getxattr(filePath, attributeName, NULL, 0, 0, 0);
    if (bufferLength <= 0) { return nil; }

    // Allocate memory for the buffer and convert it to NSString
    void *buffer = malloc(bufferLength);
    *success = getxattr(filePath, attributeName, buffer, bufferLength, 0, 0) >= 0;
    NSData *dataValue = [[NSData alloc] initWithBytes:buffer length:bufferLength];
    free(buffer);

    return dataValue;
}

static inline NSObject *objectValue(const char *filePath, const char *attributeName,
                                    Class class, BOOL *success)
{
    // Load the data from the attributes
    NSData *data = dataValue(filePath, attributeName, success);
    if (data == nil) { return nil; }

    // Decode the data
    NSError *error = nil;
    NSObject *objectValue = [NSKeyedUnarchiver unarchivedObjectOfClass:class
                                                              fromData:data
                                                                 error:&error];
    if (error != nil) {
        errno = EIO;
        NSLog(@"TOFileAttributes: Unable to decode data: '%@'", error.localizedDescription);
        return nil;
    }

    return objectValue;
}

#pragma mark - Data Formatting -

- (NSString *)attributeNameForProperty:(NSString *)propertyName
{
    // Create the formatted attribute name for the provided property
    return [NSString stringWithFormat:@"%@.%@",
            self.identifierPrefix, propertyName];
}

#pragma mark - Error Testing/Handling -

- (NSError *)captureLatestError
{
    NSString *message = nil;

    // When either `getxattr` or `setxattr` fails, it forwards the
    // error to this global variable
    switch (errno) {
        case ENOATTR:
            message = @"The extended attribute does not exist.";
            break;
        case ENOTSUP:
            message = @"The file system does not support extended attributes "
                        "or has the feature disabled.";
            break;
        case EROFS:
            message = @"The file system is mounted read-only.";
            break;
        case ERANGE:
            message = @"The data size of the attribute is out of range.";
            break;
        case EPERM:
            message = @"The named attribute is not permitted for this type of "
                        "object.";
            break;
        case EINVAL:
            message = @"The name is invalid or options has an unsupported bit set.";
            break;
        case EISDIR:
            message = @"File is a directory and not compatible with this attribute.";
            break;
        case ENOTDIR:
            message = @"A component of the path's prefix isn't a directory.";
            break;
        case ENAMETOOLONG:
            message = @"The length of the name exceeded `XATTR_MAXNAMELEN`.";
            break;
        case EACCES:
            message = @"Search permission is denied for a component of the file path or "
                        "the attribute is not allowed to be read";
            break;
        case ELOOP:
            message = @"Too many symbolic links were encountered in translating "
                        "the pathname.";
            break;
        case EFAULT:
            message = @"path or name points to an invalid address.";
            break;
        case E2BIG:
            message = @"The data size of the extended attribute is too large.";
            break;
        case ENOSPC:
            message = @"Not enough space left on the file system.";
            break;
        case EIO:
            message = @"An I/O error occurred while reading from or writing to "
                      "the file system.";
            break;
        default:
            message = @"Unable to read or write file attribute.";
    }

    return [NSError errorWithDomain:TOFileAttributesErrorDomain
                               code:errno
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

#pragma mark - Accessors -

- (void)setIdentifierPrefix:(NSString *)identifierPrefix
{
    // If no value is provided, set it to the app bundle
    if (identifierPrefix.length == 0) {
        _identifierPrefix = [[NSBundle mainBundle] bundleIdentifier];
        return;
    }

    if (identifierPrefix == _identifierPrefix) { return; }
    _identifierPrefix = identifierPrefix;
}

@end
