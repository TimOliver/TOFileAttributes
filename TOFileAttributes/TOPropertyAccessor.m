//
//  TOPropertyAccessor.m
//
//  Copyright 2018-2021 Timothy Oliver. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "TOPropertyAccessor.h"
#import <objc/runtime.h>

// -----------------------------------------------------------------------

@interface TOPropertyAccessor ()

// Determines the property name from the name of the setter selector
- (NSString *)propertyNameForSetterSelector:(SEL)selector;

// Determines the class type that any given object property may return
- (Class)returnedClassForObjectProperty:(NSString *)propertyName;

@end

// -----------------------------------------------------------------------

#pragma mark - Property Accessor Analysis -

static inline TOPropertyAccessorDataType TOPropertyAccessorDataTypeForProperty(const char *attributes)
{
    if (!attributes || strlen(attributes) == 0) { return TOPropertyAccessorDataTypeUnknown; }
    
    // Basic types are represented by a single character, following the initial "T" marker
    char propertyType = attributes[1];
    
    switch (propertyType) {
        case 'q': // Long. Merge with Integer
        case 'i': return TOPropertyAccessorDataTypeInt;
        case 'Q': // Unsigned Long. Merge with Unsigned Int
        case 'I': return TOPropertyAccessorDataTypeUnsignedInt;
        case 'd': // Double. Merge with Double
        case 'f': return TOPropertyAccessorDataTypeFloat;
        case 'B': return TOPropertyAccessorDataTypeBool;
        default: break;
    }
    
    // Objects are represented as 'T@"ClassName"', so filter for supported types
    if (propertyType != '@') { return TOPropertyAccessorDataTypeUnknown; }
    
    // Filter for specific types of objects we support
    if (strncmp(attributes + 3, "NSString", 8) == 0) {
        return TOPropertyAccessorDataTypeString;
    }
    else if (strncmp(attributes + 3, "NSArray", 7) == 0) {
        return TOPropertyAccessorDataTypeArray;
    }
    else if (strncmp(attributes + 3, "NSDictionary", 11) == 0) {
        return TOPropertyAccessorDataTypeDictionary;
    }
    else if (strncmp(attributes + 3, "NSData", 6) == 0) {
        return TOPropertyAccessorDataTypeData;
    }
    else if (strncmp(attributes + 3, "NSDate", 6) == 0) {
        return TOPropertyAccessorDataTypeDate;
    }
    
    // Return generic object
    return TOPropertyAccessorDataTypeObject;
}

static inline BOOL TOPropertyAccessorIsIgnoredProperty(const char *attributes)
{
    // Read-only properties are represented by a 'R' after the first comma
    if (strncmp(strchr(attributes, ',') + 1, "R", 1) == 0) {
        return YES;
    }
    return NO;
}

static inline char *TOPropertyAccessorClassNameForPropertyAttributes(const char *attributes)
{
    //Format is either '"'T@\"NSString\"" or '"T@\"<NSCoding>\""'
    if (strlen(attributes) < 2 || attributes[1] != '@') { return NULL; }
    
    // Get the class/protocol name
    const char *start = strstr(attributes, "\"") + 1;
    const char *end = strstr(start, "\"");
    long distance = (end - start);
    
    char *name = malloc(distance);
    strncpy(name, start, distance);
    
    return name;
}

static inline BOOL TOPropertyAccessorIsCompatibleObjectType(const char *attributes)
{
    char *name = TOPropertyAccessorClassNameForPropertyAttributes(attributes);
    if (name == NULL) { return NO; }
    
    // Check if it is a generic object that conforms to the coding protocols
    if (strcmp(name, "<NSCoding>") == 0 || strcmp(name, "<NSSecureCoding>") == 0) {
        free(name);
        return YES;
    }
    
    // If it's an object type, see if we can check if it conforms to a protocol we support
    Class class = NSClassFromString([NSString stringWithCString:name
                                                       encoding:NSUTF8StringEncoding]);
    free(name);
    
    if ([class conformsToProtocol:@protocol(NSCoding)]) {
        return YES;
    }

    return NO;
}

#pragma mark - Accessor Implementations -

// Int
static void setIntPropertyValue(TOPropertyAccessor *self, SEL _cmd, int intValue)
{
    NSString *propertyName = [self propertyNameForSetterSelector:_cmd];
    [self willChangeValueForKey:propertyName];
    [self setValue:@(intValue) forProperty:propertyName
              type:TOPropertyAccessorDataTypeInt];
    [self didChangeValueForKey:propertyName];
}

static long getIntPropertyValue(TOPropertyAccessor *self, SEL _cmd)
{
    NSString *propertyName = NSStringFromSelector(_cmd);
    return [(NSNumber *)[self valueForProperty:propertyName
                                          type:TOPropertyAccessorDataTypeInt
                                   objectClass:nil] longValue];
}

// --------

// Unsigned Int
static void setUnsignedIntPropertyValue(TOPropertyAccessor *self, SEL _cmd, unsigned int intValue)
{
    NSString *propertyName = [self propertyNameForSetterSelector:_cmd];
    [self willChangeValueForKey:propertyName];
    [self setValue:@(intValue) forProperty:propertyName
              type:TOPropertyAccessorDataTypeUnsignedInt];
    [self didChangeValueForKey:propertyName];
}

static unsigned long getUnsignedIntPropertyValue(TOPropertyAccessor *self, SEL _cmd)
{
    NSString *propertyName = NSStringFromSelector(_cmd);
    return [(NSNumber *)[self valueForProperty:propertyName
                                          type:TOPropertyAccessorDataTypeUnsignedInt
                                   objectClass:nil] unsignedIntValue];
}

// Float
static void setFloatPropertyValue(TOPropertyAccessor *self, SEL _cmd, double floatValue)
{
    NSString *propertyName = [self propertyNameForSetterSelector:_cmd];
    [self willChangeValueForKey:propertyName];
    [self setValue:@(floatValue) forProperty:propertyName
              type:TOPropertyAccessorDataTypeFloat];
    [self didChangeValueForKey:propertyName];
}

static double getFloatPropertyValue(TOPropertyAccessor *self, SEL _cmd)
{
    NSString *propertyName = NSStringFromSelector(_cmd);
    return [(NSNumber *)[self valueForProperty:propertyName
                                          type:TOPropertyAccessorDataTypeFloat
                                   objectClass:nil] doubleValue];
}

// --------

// Bool
static void setBoolPropertyValue(TOPropertyAccessor *self, SEL _cmd, BOOL boolValue)
{
    NSString *propertyName = [self propertyNameForSetterSelector:_cmd];
    [self willChangeValueForKey:propertyName];
    [self setValue:@(boolValue) forProperty:propertyName
              type:TOPropertyAccessorDataTypeBool];
    [self didChangeValueForKey:propertyName];
}

static BOOL getBoolPropertyValue(TOPropertyAccessor *self, SEL _cmd)
{
    NSString *propertyName = NSStringFromSelector(_cmd);
    return [(NSNumber *)[self valueForProperty:propertyName
                                          type:TOPropertyAccessorDataTypeBool
                                   objectClass:nil] boolValue];
}

// --------

// String
static void setStringPropertyValue(TOPropertyAccessor *self, SEL _cmd, NSString *stringValue)
{
    NSString *propertyName = [self propertyNameForSetterSelector:_cmd];
    [self willChangeValueForKey:propertyName];
    [self setValue:(NSString *)stringValue forProperty:propertyName
              type:TOPropertyAccessorDataTypeString];
    [self didChangeValueForKey:propertyName];
}

static NSString *getStringPropertyValue(TOPropertyAccessor *self, SEL _cmd)
{
    NSString *propertyName = NSStringFromSelector(_cmd);
    return (NSString *)[self valueForProperty:propertyName
                                         type:TOPropertyAccessorDataTypeString
                                  objectClass:nil];
}

// --------

//Date
static void setDatePropertyValue(TOPropertyAccessor *self, SEL _cmd, NSDate *dateValue)
{
    NSString *propertyName = [self propertyNameForSetterSelector:_cmd];
    [self willChangeValueForKey:propertyName];
    [self setValue:(NSDate *)dateValue forProperty:propertyName
              type:TOPropertyAccessorDataTypeDate];
    [self didChangeValueForKey:propertyName];
}

static NSDate *getDatePropertyValue(TOPropertyAccessor *self, SEL _cmd)
{
    NSString *propertyName = NSStringFromSelector(_cmd);
    return (NSDate *)[self valueForProperty:propertyName
                                       type:TOPropertyAccessorDataTypeDate
                                objectClass:[NSDate class]];
}

// --------

// Data
static void setDataPropertyValue(TOPropertyAccessor *self, SEL _cmd, NSData *dataValue)
{
    NSString *propertyName = [self propertyNameForSetterSelector:_cmd];
    [self willChangeValueForKey:propertyName];
    [self setValue:(NSData *)dataValue forProperty:propertyName
              type:TOPropertyAccessorDataTypeData];
    [self didChangeValueForKey:propertyName];
}

static NSData *getDataPropertyValue(TOPropertyAccessor *self, SEL _cmd)
{
    NSString *propertyName = NSStringFromSelector(_cmd);
    return (NSData *)[self valueForProperty:propertyName
                                       type:TOPropertyAccessorDataTypeData
                                objectClass:[NSData class]];
}

// --------

// Array
static void setArrayPropertyValue(TOPropertyAccessor *self, SEL _cmd, NSArray *arrayValue)
{
    NSString *propertyName = [self propertyNameForSetterSelector:_cmd];
    [self willChangeValueForKey:propertyName];
    [self setValue:arrayValue forProperty:propertyName type:TOPropertyAccessorDataTypeArray];
    [self didChangeValueForKey:propertyName];
}

static NSDictionary *getArrayPropertyValue(TOPropertyAccessor *self, SEL _cmd)
{
    NSString *propertyName = NSStringFromSelector(_cmd);
    return [self valueForProperty:propertyName
                             type:TOPropertyAccessorDataTypeArray
                      objectClass:[NSArray class]];
}

// --------

// Dictionary
static void setDictionaryPropertyValue(TOPropertyAccessor *self, SEL _cmd, NSDictionary *dictionaryValue)
{
    NSString *propertyName = [self propertyNameForSetterSelector:_cmd];
    [self willChangeValueForKey:propertyName];
    [self setValue:dictionaryValue forProperty:propertyName type:TOPropertyAccessorDataTypeDictionary];
    [self didChangeValueForKey:propertyName];
}

static NSDictionary *getDictionaryPropertyValue(TOPropertyAccessor *self, SEL _cmd)
{
    NSString *propertyName = NSStringFromSelector(_cmd);
    return [self valueForProperty:propertyName
                             type:TOPropertyAccessorDataTypeDictionary
                      objectClass:[NSDictionary class]];
}

// --------

// Object
static void setObjectPropertyValue(TOPropertyAccessor *self, SEL _cmd, id object)
{
    NSString *propertyName = [self propertyNameForSetterSelector:_cmd];
    [self willChangeValueForKey:propertyName];
    [self setValue:object forProperty:propertyName type:TOPropertyAccessorDataTypeObject];
    [self didChangeValueForKey:propertyName];
}

static id getObjectPropertyValue(TOPropertyAccessor *self, SEL _cmd)
{
    NSString *propertyName = NSStringFromSelector(_cmd);
    Class objectClass = [self returnedClassForObjectProperty:propertyName];
    return [self valueForProperty:propertyName
                             type:TOPropertyAccessorDataTypeObject
                      objectClass:objectClass];
}

// --------

static inline void TOPropertyAccessorReplaceAccessors(Class class,
                                                      NSString *name,
                                                      const char *attributes,
                                                      TOPropertyAccessorDataType type)
{
    IMP newGetter = NULL;
    IMP newSetter = NULL;
    
    switch (type) {
        case TOPropertyAccessorDataTypeInt:
            newGetter = (IMP)getIntPropertyValue;
            newSetter = (IMP)setIntPropertyValue;
            break;
            break;
        case TOPropertyAccessorDataTypeUnsignedInt:
            newGetter = (IMP)getUnsignedIntPropertyValue;
            newSetter = (IMP)setUnsignedIntPropertyValue;
            break;
        case TOPropertyAccessorDataTypeFloat:
            newGetter = (IMP)getFloatPropertyValue;
            newSetter = (IMP)setFloatPropertyValue;
            break;
        case TOPropertyAccessorDataTypeBool:
            newGetter = (IMP)getBoolPropertyValue;
            newSetter = (IMP)setBoolPropertyValue;
            break;
        case TOPropertyAccessorDataTypeString:
            newGetter = (IMP)getStringPropertyValue;
            newSetter = (IMP)setStringPropertyValue;
            break;
        case TOPropertyAccessorDataTypeDate:
            newGetter = (IMP)getDatePropertyValue;
            newSetter = (IMP)setDatePropertyValue;
            break;
        case TOPropertyAccessorDataTypeData:
            newGetter = (IMP)getDataPropertyValue;
            newSetter = (IMP)setDataPropertyValue;
            break;
        case TOPropertyAccessorDataTypeArray:
            newGetter = (IMP)getArrayPropertyValue;
            newSetter = (IMP)setArrayPropertyValue;
            break;
        case TOPropertyAccessorDataTypeDictionary:
            newGetter = (IMP)getDictionaryPropertyValue;
            newSetter = (IMP)setDictionaryPropertyValue;
            break;
        case TOPropertyAccessorDataTypeObject:
            newGetter = (IMP)getObjectPropertyValue;
            newSetter = (IMP)setObjectPropertyValue;
            break;
        default:
            break;
    }
    
    if (newGetter == NULL || newSetter == NULL) { return; }
    
    // Generate synthesized setter method name
    NSString *setterName = [NSString stringWithFormat:@"set%@%@:",
                            [[name substringToIndex:1] capitalizedString],
                            [name substringFromIndex:1]];

    // Convert the string names to selectors
    SEL originalGetter = NSSelectorFromString(name);
    SEL originalSetter = NSSelectorFromString(setterName);

    // Compare the current implementations and skip if they match with the new ones
    // (Eg, we've already replaced these implementations)
    IMP originalGetterImplementation = class_getMethodImplementation(class, originalGetter);
    IMP originalSetterImpelemtation = class_getMethodImplementation(class, originalSetter);
    if (originalGetterImplementation == newGetter && originalSetterImpelemtation == newSetter) {
        return;
    }

    // If the class already has that selector, replace it.
    // Otherwise, add as a new method
    if ([class instancesRespondToSelector:originalGetter]) {
        class_replaceMethod(class, originalGetter, newGetter, attributes);
    }
    else {
        class_addMethod(class, originalGetter, newGetter, attributes);
    }
    
    // Repeat for setter
    if ([class instancesRespondToSelector:originalSetter]) {
        class_replaceMethod(class, originalSetter, newSetter, attributes);
    }
    else {
        class_addMethod(class, originalSetter, newSetter, attributes);
    }
}

static inline void TOPropertyAccessorSwapClassPropertyAccessors(Class class)
{
    // Get a list of all of the ignored properties defined by this subclass
    NSArray *ignoredProperties = [class ignoredProperties];
    
    // Get all properties in this class
    unsigned int propertyCount;
    objc_property_t *properties = class_copyPropertyList(class, &propertyCount);
    
    // Loop through each property
    for (NSInteger i = 0; i < propertyCount; i++) {
        // Get the property from the class
        objc_property_t property = properties[i];
        
        // Check if the property is read-only
        const char *attributes = property_getAttributes(property);
        if (TOPropertyAccessorIsIgnoredProperty(attributes)) { continue; }
        
        // Get the type of this property
        TOPropertyAccessorDataType type = TOPropertyAccessorDataTypeForProperty(attributes);
        if (type == TOPropertyAccessorDataTypeUnknown) { continue; }
        
        // Get the name and check if it was explicitly ignored
        NSString *name = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        if (ignoredProperties.count && [ignoredProperties indexOfObject:name] != NSNotFound) { continue; }
        
        // Check if it's an object type we can support
        if (type == TOPropertyAccessorDataTypeObject &&
            TOPropertyAccessorIsCompatibleObjectType(attributes) == NO) { continue; }
        
        // Perform the method swap
        TOPropertyAccessorReplaceAccessors(class, name, attributes, type);
    }
    free(properties);
}

// -----------------------------------------------------------------------

@implementation TOPropertyAccessor

#pragma mark - Class Creation -

- (instancetype)init
{
    // Before first init, perform the Objective-C runtime swap of all of this class's properties
    TOPropertyAccessorSwapClassPropertyAccessors(self.class);
    if (self = [super init]) { }
    return self;
}

#pragma mark - KVC Compliance -

- (id)objectForKeyedSubscript:(NSString *)key
{
    return [self valueForKey:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key
{
    [self setValue:obj forKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    // If it's a property we don't manage, defer to the super class
    if ([self isIgnoredProperty:key]) {
        [super setValue:value forKey:key];
        return;
    }
    
    // Work out what type of object this is from the schema
    TOPropertyAccessorDataType type = [self typeForPropertyWithName:key];
    if (type == TOPropertyAccessorDataTypeUnknown) {
        [super setValue:value forKey:key];
        return;
    }

    // Inform KVO the property is changing
    [self willChangeValueForKey:key];
    
    // Set the new value for this property
    [self setValue:value forProperty:key type:type];
    
    // Inform KVO the key has changed
    [self didChangeValueForKey:key];
}

- (id)valueForKey:(NSString *)key
{
    if ([self isIgnoredProperty:key]) {
        return [super valueForKey:key];
    }
    
    // Work out what type of object this is from the schema
    TOPropertyAccessorDataType type = [self typeForPropertyWithName:key];
    if (type == TOPropertyAccessorDataTypeUnknown) { return [super valueForKey:key]; }

    Class objectClass = nil;
    if (type == TOPropertyAccessorDataTypeObject) {
        objectClass = [self returnedClassForObjectProperty:key];
    }

    // Get the value straight from the backing store
    return [self valueForProperty:key type:type objectClass:objectClass];
}

- (BOOL)isIgnoredProperty:(NSString *)property
{
    NSArray *ignoredProperties = [[self class] ignoredProperties];
    return (ignoredProperties.count && [ignoredProperties indexOfObject:property] != NSNotFound);
}

- (TOPropertyAccessorDataType)typeForPropertyWithName:(NSString *)propertyName
{
    objc_property_t property = class_getProperty([self class], propertyName.UTF8String);
    if (property == NULL) { return TOPropertyAccessorDataTypeUnknown; }
    
    return TOPropertyAccessorDataTypeForProperty(property_getAttributes(property));
}

#pragma mark - Subclass Overridable -

- (nullable id)valueForProperty:(NSString *)propertyName
                           type:(TOPropertyAccessorDataType)type
                    objectClass:(nullable Class)objectClass { return nil; }
- (void)setValue:(_Nullable id)value forProperty:(NSString *)propertyName
            type:(TOPropertyAccessorDataType)type { }
+ (nullable NSArray *)ignoredProperties { return nil; }

#pragma mark - Static State Management -
+ (NSString *)instanceKeyNameWithIdentifier:(NSString *)identifier
{
    NSString *className = NSStringFromClass(self.class);
    
    // Swift classes namespace their names with the product name.
    // That's not necessary here, so strip it out
    NSRange range = [className rangeOfString:@"."];
    if (range.location != NSNotFound) {
        className = [className substringFromIndex:range.location + 1];
    }

    // If this instance doesn't have an identifier, just return the class name
    if (identifier.length == 0) {
        return className;
    }
    
    return [NSString stringWithFormat:@"%@.%@", className, identifier];
}

#pragma mark - Dynamic Accessor Handling -

- (NSString *)propertyNameForSetterSelector:(SEL)selector
{
    NSString *propertyName = NSStringFromSelector(selector);
    //Drop the ":" at the end
    propertyName = [propertyName substringToIndex:propertyName.length - 1];
    //Remove the "set" at the beginning
    propertyName = [propertyName substringFromIndex:3];
    //Make the first letter lowercase
    propertyName = [NSString stringWithFormat:@"%@%@",
                    [propertyName substringToIndex:1].lowercaseString,
                    [propertyName substringFromIndex:1]];
    
    return propertyName;
}

- (Class)returnedClassForObjectProperty:(NSString *)propertyName
{
    objc_property_t property = class_getProperty([self class],
                                                 propertyName.UTF8String);
    if (property == NULL) { return nil; }

    // Retrieve the attributes string of this property
    const char *attributes = property_getAttributes(property);

    // Get the class name that this property is expected to return
    char *className = TOPropertyAccessorClassNameForPropertyAttributes(attributes);
    if (className == NULL) { return nil; }

    // Convert to NSString and then return the class
    return NSClassFromString([NSString stringWithCString:className
                                                encoding:NSUTF8StringEncoding]);
}

@end
