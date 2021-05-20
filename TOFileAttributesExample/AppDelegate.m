//
//  AppDelegate.m
//  TOFileAttributesExample
//
//  Created by Tim Oliver on 20/5/21.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [[UIViewController alloc] init];
    self.window.rootViewController.view.backgroundColor = [UIColor systemBackgroundColor];
    [self.window makeKeyAndVisible];

    return YES;
}

@end
