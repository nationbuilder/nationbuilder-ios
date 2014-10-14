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
#import <NBClient/UI.h>

#import "NBPeopleDataSource.h"
#import "NBPeopleViewController.h"

@interface NBAppDelegate ()

@property (nonatomic, strong) NBAccount *account;
@property (nonatomic, strong) NBPeopleViewController *peopleViewController;
@property (nonatomic, strong) UINavigationController *rootViewController;

@end

@implementation NBAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Crashlytics startWithAPIKey:@"40c37689b7be7476400be06f7b2784cc8697c931"];
    [self.account requestActiveWithCompletionHandler:^(NSError *error) {
        if (error) {
            [[UIAlertView nb_genericAlertViewWithError:error] show];
            return;
        }
        NBAccountButton *button = [[NSBundle mainBundle] loadNibNamed:@"NBAccountButton" owner:self options:nil].firstObject;
        button.dataSource = self.account;
        button.avatarImageView.hidden = YES;
        [self.peopleViewController.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:button]
                                                              animated:YES];
        self.peopleViewController.ready = YES;
    }];
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
    NSError *error;
    BOOL didOpen = [NBAuthenticator finishAuthenticatingInWebBrowserWithURL:url error:&error];
    if (error) {
        [[UIAlertView nb_genericAlertViewWithError:error] show];
    }
    return didOpen;
}

#pragma mark - Private

- (NBAccount *)account
{
    if (_account) {
        return _account;
    }
    NSDictionary *customClientInfo;
#if defined(DEBUG) && TARGET_IPHONE_SIMULATOR
    // NOTE: This configuration file is meant for internal use only, unless
    // you have a development-specific set of NationBuilder configuration.
    customClientInfo = [NSDictionary dictionaryWithContentsOfFile:
            [[NSBundle mainBundle] pathForResource:[NBInfoFileName stringByAppendingString:@"-Local"] ofType:@"plist"]];
#endif
    self.account = [[NBAccount alloc] initWithClientInfo:customClientInfo];
    //self.account.shouldUseTestToken = YES;
#if DEBUG_LOGIN
    [NBAuthenticationCredential deleteCredentialWithIdentifier:self.account.client.authenticator.credentialIdentifier];
#endif
    return _account;
}

- (NBPeopleViewController *)peopleViewController
{
    if (_peopleViewController) {
        return _peopleViewController;
    }
    self.peopleViewController = [[NBPeopleViewController alloc] initWithNibNames :nil bundle:nil];
    self.peopleViewController.dataSource = [[NBPeopleDataSource alloc] initWithClient:self.account.client];
    self.peopleViewController.title = NSLocalizedString(@"people.navigation-title", nil);
    return _peopleViewController;
}

- (UIViewController *)rootViewController
{
    if (_rootViewController) {
        return _rootViewController;
    }
    self.rootViewController = [[UINavigationController alloc] initWithRootViewController:self.peopleViewController];
    self.rootViewController.view.backgroundColor = [UIColor whiteColor];
    return _rootViewController;
}

@end
