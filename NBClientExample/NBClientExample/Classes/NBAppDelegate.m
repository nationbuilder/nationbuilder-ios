//
//  NBAppDelegate.m
//  NBClientExample
//
//  Created by Peng Wang on 7/8/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBAppDelegate.h"

#import <Crashlytics/Crashlytics.h>

#import <NBClient/Main.h>

@interface NBAppDelegate ()

@property (nonatomic, strong) NBClient *client;
@property (nonatomic, strong) UIViewController *rootViewController;

@end

@implementation NBAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Crashlytics startWithAPIKey:@"40c37689b7be7476400be06f7b2784cc8697c931"];
    [UICollectionView appearance].backgroundColor = [UIColor whiteColor];
    // END: Customization.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.rootViewController;
    [self.window makeKeyAndVisible];
    return YES;
}

#pragma mark - Private

- (NBClient *)client
{
    if (_client) {
        return _client;
    }
    NSDictionary *environment = [NSProcessInfo processInfo].environment;
    if (environment[@"NBNationName"]) {
        NSString *baseURLString = [NSString stringWithFormat:environment[@"NBBaseURLFormat"], environment[@"NBNationName"]];
        NSURL *url = [NSURL URLWithString:baseURLString];
        self.client = [[NBClient alloc] initWithNationName:environment[@"NBNationName"]
                                                    apiKey:environment[@"NBClientAPIKey"]
                                             customBaseURL:url
                                          customURLSession:nil customURLSessionConfiguration:nil];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"FAIL" message:@"FAIL" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil] show];
    }
    return _client;
}

@end
