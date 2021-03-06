//
//  TOTestAttributes.h
//  TOFileAttributesExample
//
//  Created by Tim Oliver on 23/5/21.
//

#import "TOFileAttributes.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TOTestAttributes : TOFileAttributes

@property (nonatomic, assign) NSInteger integerValue;
@property (nonatomic, assign) NSInteger unsignedIntegerValue;
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
