//
//  TOFileAttributes.m
//  TOFileAttributesExample
//
//  Created by Tim Oliver on 20/5/21.
//

#import "TOFileAttributes.h"
#import <sys/xattr.h>

@interface TOFileAttributes ()

@property (nonatomic, strong, readwrite) NSURL *fileURL;

@end

@implementation TOFileAttributes

#pragma mark - Object Creation -

- (instancetype)initWithFileURL:(NSURL *)fileURL
{
    if (self = [super init]) {
        _fileURL = fileURL;
        [self commonInit];
    }

    return self;
}

- (void)commonInit
{
    // Force it to load its default value
    self.identifierPrefix = nil;
}

#pragma mark - Property Accessor Implementation -

- (nullable id)valueForProperty:(NSString *)propertyName
                           type:(TOPropertyAccessorDataType)type
{
    const char *attributeName = [[self attributeNameForProperty:propertyName]
                                 cStringUsingEncoding:NSUTF8StringEncoding];
    const char *filePath = [self.fileURL.path cStringUsingEncoding:NSUTF8StringEncoding];

    switch (type) {
        case TOPropertyAccessorDataTypeInt: return intValue(filePath, attributeName);
        case TOPropertyAccessorDataTypeFloat: return floatValue(filePath, attributeName);
        case TOPropertyAccessorDataTypeDouble: return doubleValue(filePath, attributeName);
        case TOPropertyAccessorDataTypeBool: return boolValue(filePath, attributeName);
        case TOPropertyAccessorDataTypeDate:
        case TOPropertyAccessorDataTypeString:
        case TOPropertyAccessorDataTypeData:
        case TOPropertyAccessorDataTypeArray:
        case TOPropertyAccessorDataTypeDictionary:
        case TOPropertyAccessorDataTypeObject:
        default: return nil;
    }
}

- (void)setValue:(_Nullable id)value
     forProperty:(NSString *)propertyName
            type:(TOPropertyAccessorDataType)type
{
    NSString *attributeName = [self attributeNameForProperty:propertyName];
}

#pragma mark - File Attribute Getters -

static inline NSNumber *intValue(const char *filePath, const char *attributeName)
{
    long integerValue = 0;
    getxattr(filePath, attributeName, &integerValue, sizeof(long), 0, 0);
    return @(integerValue);
}

static inline NSNumber *floatValue(const char *filePath, const char *attributeName)
{
    CGFloat floatValue = 0;
    getxattr(filePath, attributeName, &floatValue, sizeof(CGFloat), 0, 0);
    return @(floatValue);
}

static inline NSNumber *doubleValue(const char *filePath, const char *attributeName)
{
    double doubleValue = 0;
    getxattr(filePath, attributeName, &doubleValue, sizeof(double), 0, 0);
    return @(doubleValue);
}

static inline NSNumber *boolValue(const char *filePath, const char *attributeName)
{
    BOOL boolValue = 0;
    getxattr(filePath, attributeName, &boolValue, sizeof(double), 0, 0);
    return @(boolValue);
}

#pragma mark - Data Formatting -

- (NSString *)attributeNameForProperty:(NSString *)propertyName
{
    // Create the formatted attribute name for the provided property
    return [NSString stringWithFormat:@"%@.%@",
            self.identifierPrefix, propertyName];
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
