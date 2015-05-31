//
//  NBAppDelegate.m
//  NBClientExample
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import "NBAppDelegate.h"

#import <NBClient/Main.h>
#import <NBClient/UI.h>

#import "NBPeopleViewDataSource.h"
#import "NBPeopleViewController.h"

#import "NBPeopleViewFlowLayout.h"

@interface NBAppDelegate () <NBAccountsManagerDelegate>

@property (nonatomic, readonly) NBAccount *account;

@property (nonatomic) NBAccountButton *accountButton;
@property (nonatomic) NBAccountsManager *accountsManager;
@property (nonatomic) NBAccountsViewController *accountsViewController;

@property (nonatomic, copy) NSDictionary *customClientInfo;
@property (nonatomic) NBPeopleViewController *peopleViewController;

- (IBAction)presentAccountsViewController:(id)sender;

@end

@implementation NBAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [application nb_loadBundleResources];
    // Configure log levels. Default is 'Debug' for debug configurations and
    // 'Warning' for release configurations. For example, by setting client
    // logging to warning level during development parts of the sample app
    // unrelated to the client, the noise in our log is reduced.
    /*
    [NBAccountsManager updateLoggingToLevel:NBLogLevelWarning];
    [NBAuthenticator updateLoggingToLevel:NBLogLevelWarning];
    */
    [NBClient updateLoggingToLevel:NBLogLevelWarning];
    // You can also implement NBLogging in your own classes and use the NBLog macros.
    [NBPeopleViewFlowLayout updateLoggingToLevel:NBLogLevelInfo];
#if defined(DEBUG) && TARGET_IPHONE_SIMULATOR
    // NOTE: This configuration file is meant for internal use only, unless
    // you have a development-specific set of NationBuilder configuration.
    self.customClientInfo = [NSDictionary dictionaryWithContentsOfFile:
                             [[NSBundle mainBundle] pathForResource:[NBInfoFileName stringByAppendingString:@"-Local"] ofType:@"plist"]];
#endif
    // Setup accounts aspect.
    self.accountButton = [NBAccountButton accountButtonFromNibWithTarget:self action:@selector(presentAccountsViewController:)];
    self.accountsManager = [[NBAccountsManager alloc] initWithClientInfo:self.customClientInfo delegate:self];
    self.accountsViewController = [[NBAccountsViewController alloc] initWithNibName:nil bundle:nil];
    self.accountButton.dataSources = self.accountsManager;
    self.accountsViewController.dataSource = self.accountsManager;
    // Pass our account button to the view controller that will show it for
    // further configuration. Please refer to the method for configuration options.
    [self.peopleViewController showAccountButton:self.accountButton];
    // Boilerplate.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:self.peopleViewController];
    self.window.rootViewController.view.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    // In addition to setting CFBundleURLTypes, this is the basics of what is
    // required for the preferred way of authenticating against NationBuilder.
    [NBAuthenticator finishAuthenticatingInWebBrowserWithURL:url];
    // You should return NO regardless of whether or not the authentication
    // succeeded. There's a system-level bug that prevents your app from opening
    // the same URL after a previous successful opening.
    return NO;
}

#pragma mark - NBAccountsManagerDelegate

- (void)accountsManager:(NBAccountsManager *)accountsManager didFailToSwitchToAccount:(NBAccount *)account withError:(NSError *)error
{
    // Show an alert for generic errors
    if (error.code != NBAuthenticationErrorCodeUser) {
        [[UIAlertView nb_genericAlertViewWithError:error] show];
    }
}

- (void)accountsManager:(NBAccountsManager *)accountsManager didSignOutOfInvalidAccount:(NBAccount *)account fromHTTPError:(NSError *)error
{
    NBLog(@"INFO: Setting app to not ready and presenting accounts view for re-authenticating");
    [self presentAccountsViewController:nil];
    self.peopleViewController.busy = NO;
}

- (void)accountsManager:(NBAccountsManager *)accountsManager willAddAccount:(NBAccount *)account
{
#if DEBUG_LOGIN
    [NBAuthenticationCredential deleteCredentialWithIdentifier:account.authenticator.credentialIdentifier];
#endif
}

- (void)accountsManager:(NBAccountsManager *)accountsManager didSwitchToAccount:(NBAccount *)account
{
    // If we have a new / different account.
    if (account) {
        // Clear out our data.
        self.peopleViewController.dataSource = [[NBPeopleViewDataSource alloc] initWithClient:account.client];
        // If the accounts view was shown to sign in initially, the user probably just wants to start using the app.
        if (!self.peopleViewController.ready) {
            // Dismiss the accounts view if needed.
            // NOTE: The accounts view has a custom dismissal that works with
            // -showWithAccountButton:presentingViewController.
            [self.accountsViewController dismissViewControllerAnimated:YES completion:nil];
            // Set our view controller to ready.
            self.peopleViewController.ready = YES;
        }
    // If we're no longer signed in, update our app.
    } else if (!account && !accountsManager.isSignedIn && self.peopleViewController.ready) {
        self.peopleViewController.ready = NO;
    }
}

#pragma mark - Actions

- (IBAction)presentAccountsViewController:(id)sender
{
    [self.accountsViewController showWithAccountButton:self.accountButton
                              presentingViewController:self.window.rootViewController];
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
     
     Also remember to integrate NBAccountButton and sign-in state support in
     your view controller.
     */
    return (NBAccount *)self.accountsManager.selectedAccount;
}

- (NBPeopleViewController *)peopleViewController
{
    if (_peopleViewController) {
        return _peopleViewController;
    }
    self.peopleViewController = [[NBPeopleViewController alloc] initWithNibNames :nil bundle:nil];
    self.peopleViewController.title = NSLocalizedString(@"people.navigation-title", nil);
    return _peopleViewController;
}

@end
