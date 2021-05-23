//
//  TOTestAttributes.h
//  TOFileAttributesExample
//
//  Created by Tim Oliver on 23/5/21.
//

#import "TOFileAttributes.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

//TOPropertyAccessorDataTypeUnknown,
//TOPropertyAccessorDataTypeInt,
//TOPropertyAccessorDataTypeFloat,
//TOPropertyAccessorDataTypeDouble,
//TOPropertyAccessorDataTypeBool,
//TOPropertyAccessorDataTypeDate,
//TOPropertyAccessorDataTypeString,
//TOPropertyAccessorDataTypeData,
//TOPropertyAccessorDataTypeArray,
//TOPropertyAccessorDataTypeDictionary,
//TOPropertyAccessorDataTypeObject

@interface TOTestAttributes : TOFileAttributes

@property (nonatomic, assign) NSUInteger integerValue;
@property (nonatomic, assign) CGFloat floatValue;
@property (nonatomic, assign) double doubleValue;
@property (nonatomic, assign) BOOL boolValue;
@property (nonatomic, strong) NSDate *dateValue;
@property (nonatomic, copy) NSString *stringValue;
@property (nonatomic, strong) NSData *dataValue;
@property (nonatomic, strong) NSArray *arrayValue;
@property (nonatomic, strong) NSDictionary *dictionaryValue;
@property (nonatomic, strong) UIColor *colorValue;

@end

NS_ASSUME_NONNULL_END
