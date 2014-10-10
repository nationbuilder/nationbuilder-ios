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

#import "NBPeopleDataSource.h"
#import "NBPeopleViewController.h"

@interface NBAppDelegate ()

@property (nonatomic, strong) NBClient *client;
@property (nonatomic, strong) UINavigationController *rootViewController;

@end

@implementation NBAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Crashlytics startWithAPIKey:@"40c37689b7be7476400be06f7b2784cc8697c931"];
    // END: Customization.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.rootViewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    // In addition to setting CFBundleURLTypes, this is the basics of what is
    // required for the preferred way of authenticating against NationBuilder.
    BOOL didOpen = NO;
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSDictionary *parameters = [components.fragment nb_queryStringParametersWithEncoding:NSUTF8StringEncoding];
    if (parameters[NBAuthenticationRedirectTokenKey]) {
        self.client.apiKey = parameters[NBAuthenticationRedirectTokenKey];
        didOpen = YES;
    }
    return didOpen;
}

#pragma mark - Private

- (NBClient *)client
{
    if (_client) {
        return _client;
    }
    NSString *pathName;
#if defined(DEBUG) && TARGET_IPHONE_SIMULATOR
    // NOTE: This configuration file is meant for internal use only, unless
    // you have a development-specific set of NationBuilder configuration.
    pathName = [NBInfoFileName stringByAppendingString:@"-Local"];
#endif
    pathName = pathName ?: NBInfoFileName;
    NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:pathName ofType:@"plist"]];
    NSString *baseURLString = [NSString stringWithFormat:info[NBInfoBaseURLFormatKey], info[NBInfoNationNameKey]];
    NSURL *url = [NSURL URLWithString:baseURLString];
    self.client = [[NBClient alloc] initWithNationName:info[NBInfoNationNameKey]
                                                apiKey:info[NBInfoTestTokenKey]
                                         customBaseURL:url
                                      customURLSession:nil customURLSessionConfiguration:nil];
    return _client;
}

- (UIViewController *)rootViewController
{
    if (_rootViewController) {
        return _rootViewController;
    }
    NBPeopleDataSource *dataSource = [[NBPeopleDataSource alloc] initWithClient:self.client];
    NBPeopleViewController *viewController = [[NBPeopleViewController alloc] initWithNibNames:nil bundle:nil];
    viewController.dataSource = dataSource;
    viewController.title = NSLocalizedString(@"people.navigation-title", nil);
    self.rootViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.rootViewController.view.backgroundColor = [UIColor whiteColor];
    return _rootViewController;
}

@end
