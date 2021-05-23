//
//  AppDelegate.m
//  TOFileAttributesExample
//
//  Created by Tim Oliver on 20/5/21.
//

#import "AppDelegate.h"
#import "TOTestAttributes.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)testFileAttributes
{
    // Create the attributes object
    TOTestAttributes *attributes = [TOTestAttributes attributesWithFileURL:self.fileURL];

    NSLog(@"Writing attributes to disk");

    // Test writing attributes out to the file
    attributes.integerValue = 1;
    attributes.floatValue = 0.5;
    attributes.doubleValue = 0.3;
    attributes.boolValue = YES;
    attributes.stringValue = @"Hello World!";
    attributes.dateValue = [NSDate date];
    attributes.dataValue = [@"Hello data!" dataUsingEncoding:NSUTF8StringEncoding];
    attributes.arrayValue = @[@"Hello", @"World"];
    attributes.dictionaryValue = @{@"Greeting": @"Hello world" };
    attributes.colorValue = [UIColor redColor];

    NSLog(@"File written. Reading back values.");

    NSLog(@"Integer value: %ld", (long)attributes.integerValue);
    NSLog(@"Float value: %f", attributes.floatValue);
    NSLog(@"Double value: %f", attributes.doubleValue);
    NSLog(@"Bool value: %d", attributes.boolValue);
    NSLog(@"String value: %@", attributes.stringValue);
    NSLog(@"Date value: %@", attributes.dateValue);
    NSLog(@"Data value: %@", attributes.dataValue);
    NSLog(@"Array value: %@", attributes.arrayValue);
    NSLog(@"Dictionary value: %@", attributes.dictionaryValue);
    NSLog(@"Color value: %@", attributes.colorValue);
}

- (NSURL *)fileURL
{
    // Make a file we can test writing attributes to.
    // Delete the file if it already exists
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsURL = [fileManager URLsForDirectory:NSDocumentDirectory
                                              inDomains:NSUserDomainMask].firstObject;
    NSURL *fileURL = [documentsURL URLByAppendingPathComponent:@"TestFile.txt"];

    if ([fileManager fileExistsAtPath:fileURL.path]) {
        [fileManager removeItemAtPath:fileURL.path error:nil];
    }

    [@"Hello World" writeToFile:fileURL.path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    return fileURL;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [[UIViewController alloc] init];
    self.window.rootViewController.view.backgroundColor = [UIColor systemBackgroundColor];
    [self.window makeKeyAndVisible];

    [self testFileAttributes];

    return YES;
}

@end
