//
//  TOFileAttributesTests.m
//  TOFileAttributesTests
//
//  Created by Tim Oliver on 23/5/21.
//

#import <XCTest/XCTest.h>
#import "TOFileAttributes.h"
#import <UIKit/UIKit.h>

// A test class featuring all of the supported types
@interface TOTestFileAttributes : TOFileAttributes
@property (nonatomic, assign) NSInteger integerValue;
@property (nonatomic, assign) NSInteger unsignedIntegerValue;
@property (nonatomic, assign) CGFloat floatValue;
@property (nonatomic, assign) BOOL boolValue;
@property (nonatomic, strong) NSDate *dateValue;
@property (nonatomic, copy) NSString *stringValue;
@property (nonatomic, strong) NSData *dataValue;
@property (nonatomic, strong) NSArray *arrayValue;
@property (nonatomic, strong) NSDictionary *dictionaryValue;
@property (nonatomic, strong) UIColor *colorValue;
@end

@implementation TOTestFileAttributes
@end

// --------------------------------------------------------

@interface TOFileAttributesTests : XCTestCase

@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) NSURL *fileURL;

@end

@implementation TOFileAttributesTests

- (void)setUp
{
    // Get a reference to the file manager
    self.fileManager = [NSFileManager defaultManager];

    // Generate a new file from scratch to test against
    NSURL *tempDirectory = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    NSString *fileName = [NSString stringWithFormat:@"%@.txt", [NSUUID UUID].UUIDString];
    self.fileURL = [tempDirectory URLByAppendingPathComponent:fileName];

    // Make a test file at that location
    [@"TOFileAttributesTests" writeToFile:self.fileURL.path
                               atomically:YES
                                 encoding:NSUTF8StringEncoding
                                    error:nil];
}

- (void)tearDown
{
    [self.fileManager removeItemAtPath:self.fileURL.path error:nil];
}

// Test that a valid instance is returned when the URL points to a valid file,
// and nil otherwise
- (void)testCreatingInstances
{
    // Test with a valid file URL
    TOTestFileAttributes *attributes = [[TOTestFileAttributes alloc] initWithFileURL:self.fileURL
                                                                      cached:NO];
    XCTAssertNotNil(attributes);

    // Test with a garbage URL
    NSURL *invalidURL = [NSURL URLWithString:@"http://tim.dev"];
    attributes = [[TOTestFileAttributes alloc] initWithFileURL:invalidURL
                                                    cached:NO];
    XCTAssertNil(attributes);
}

- (void)testAttributeProperties
{
    
}

@end
