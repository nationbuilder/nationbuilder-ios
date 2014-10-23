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

@interface NBAppDelegate () <NBAccountsManagerDelegate, NBAccountsViewDelegate>

@property (nonatomic, strong, readonly) NBAccount *account;
@property (nonatomic, strong) NBAccountButton *accountButton;
@property (nonatomic, strong) NBAccountsManager *accountsManager;
@property (nonatomic, strong) NBAccountsViewController *accountsViewController;

@property (nonatomic, strong) NSDictionary *customClientInfo;
@property (nonatomic, strong) NBPeopleViewController *peopleViewController;
@property (nonatomic, strong) UINavigationController *rootViewController;

- (IBAction)presentAccountsViewController:(id)sender;

@end

@implementation NBAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Crashlytics startWithAPIKey:@"40c37689b7be7476400be06f7b2784cc8697c931"];
#if defined(DEBUG) && TARGET_IPHONE_SIMULATOR
    // NOTE: This configuration file is meant for internal use only, unless
    // you have a development-specific set of NationBuilder configuration.
    self.customClientInfo = [NSDictionary dictionaryWithContentsOfFile:
                             [[NSBundle mainBundle] pathForResource:[NBInfoFileName stringByAppendingString:@"-Local"] ofType:@"plist"]];
#endif
    // Boilerplate.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.rootViewController;
    [self.window makeKeyAndVisible];
    // END: Boilerplate.
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    // In addition to setting CFBundleURLTypes, this is the basics of what is
    // required for the preferred way of authenticating against NationBuilder.
    NSError *error;
    [NBAuthenticator finishAuthenticatingInWebBrowserWithURL:url error:&error];
    if (error) {
        [[UIAlertView nb_genericAlertViewWithError:error] show];
    }
    // You should return NO regardless of whether or not the authentication
    // succeeded. There's a system-level bug that prevents your app from opening
    // the same URL after a previous successful opening.
    return NO;
}

#pragma mark - NBAccountsManagerDelegate

- (void)accountsManager:(NBAccountsManager *)accountsManager failedToSwitchToAccount:(NBAccount *)account withError:(NSError *)error
{
}

- (void)accountsManager:(NBAccountsManager *)accountsManager willAddAccount:(NBAccount *)account
{
#if DEBUG_LOGIN
    [NBAuthenticationCredential deleteCredentialWithIdentifier:account.client.authenticator.credentialIdentifier];
#endif
}

- (void)accountsManager:(NBAccountsManager *)accountsManager didSwitchToAccount:(NBAccount *)account
{
    // Update the account button.
    self.accountButton.dataSource = account;
    // If we have a new / different account.
    if (account) {
        // Clear out our data.
        self.peopleViewController.dataSource = [[NBPeopleDataSource alloc] initWithClient:account.client];
        // If the accounts view was shown to sign in initially, the user probably just wants to start using the app.
        if (!self.peopleViewController.ready) {
            // Dismiss the accounts view if needed.
            if (self.rootViewController.visibleViewController == self.accountsViewController) {
                [self.rootViewController dismissViewControllerAnimated:YES completion:nil];
            }
            // Set our view controller to ready.
            self.peopleViewController.ready = YES;
        }
    // If we're no longer signed in, update our app.
    } else if (!account && !accountsManager.isSignedIn && self.peopleViewController.ready) {
        self.peopleViewController.ready = NO;
    }
}

#pragma mark - Private

- (NBAccount *)account
{
    /**
     Instead of using a full-blown account manager, and if you're only building
     the app for one nation to use and don't want to give your users the ability
     to switch between multiple user accounts, you can use NBAccount by itself.
     
     Just create an account and pass it directly to `self.accountButton`:
     
     [[NBAccount alloc] initWithClientInfo:self.customClientInfo];
     
     Also remember to include
     */
    return (NBAccount *)self.accountsManager.selectedAccount;
}

- (NBAccountButton *)accountButton
{
    if (_accountButton) {
        return _accountButton;
    }
    self.accountButton = [[NSBundle mainBundle] loadNibNamed:@"NBAccountButton" owner:self options:nil].firstObject;
    [self.accountButton addTarget:self action:@selector(presentAccountsViewController:) forControlEvents:UIControlEventTouchUpInside];
    return _accountButton;
}

- (NBAccountsManager *)accountsManager
{
    if (_accountsManager) {
        return _accountsManager;
    }
    self.accountsManager = [[NBAccountsManager alloc] initWithClientInfo:self.customClientInfo];
    self.accountsManager.delegate = self;
    return _accountsManager;
}

- (NBAccountsViewController *)accountsViewController
{
    if (_accountsViewController) {
        return _accountsViewController;
    }
    self.accountsViewController = [[NBAccountsViewController alloc] initWithNibName:nil bundle:nil];
    self.accountsViewController.dataSource = self.accountsManager;
    self.accountsViewController.delegate = self;
    return _accountsViewController;
}

- (NBPeopleViewController *)peopleViewController
{
    if (_peopleViewController) {
        return _peopleViewController;
    }
    self.peopleViewController = [[NBPeopleViewController alloc] initWithNibNames :nil bundle:nil];
    self.peopleViewController.title = NSLocalizedString(@"people.navigation-title", nil);
    if (!self.accountsManager.isSignedIn) {
        self.peopleViewController.notReadyLabel.text = NSLocalizedString(@"message.sign-in", nil);
    }
    [self.peopleViewController showAccountButton:self.accountButton];
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

- (void)presentAccountsViewController:(id)sender
{
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.accountsViewController];
    navigationController.view.backgroundColor = [UIColor whiteColor];
    [self.rootViewController presentViewController:navigationController animated:YES completion:nil];
}

@end
