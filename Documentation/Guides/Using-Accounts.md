# Using Accounts

The accounts layer of the SDK is the top layer that we suggest you use. You can
use accounts to better represent users and user sessions. You should also use
the account management feature. It will add multi-account, multi-nation support
to your app. Read on to learn more about the entire accounts layer.

<!-- MarkdownTOC -->

- [NBAccount](#nbaccount)
    - [Sign in](#sign-in)
    - [Sign out](#sign-out)
- [NBAccountButton](#nbaccountbutton)
- [NBAccountsManager](#nbaccountsmanager)
    - [Sign in](#sign-in-1)
    - [Sign out](#sign-out-1)
- [NBAccountsViewController](#nbaccountsviewcontroller)
    - [Presentation](#presentation)
- [Delegation](#delegation)
    - [Handling Stale Tokens](#handling-stale-tokens)
- [Notes](#notes)
    - [Custom UI](#custom-ui)
    - [Appearance](#appearance)

<!-- /MarkdownTOC -->

## NBAccount

NBAccount is a model that builds upon the NBClient and NBAuthenticator. It helps
manage these two components and acts as their delegate when needed. It will
create them based on client info you provide. You can provide this info during
initialization:

```objectivec
#import <NBClient/NBAccount.h>

@interface MYAppDelegate () <NBAccountDelegate> @end
// Implement delegate methods...

NBAccount *account = [[NBAccount alloc] initWithClientInfo:nil delegate:self];
```

__Note:__ Passing client info during initialization is optional. If you provide
nothing, the account will look for the default client info in a file in your
application bundle. Make sure to call it `NationBuilder-Info.plist`. Here is what
you must put in the plist (or the dictionary):

|       Key       |        Key Constant       |         Sample Value         |
|-----------------|---------------------------|------------------------------|
| Client ID       | NBInfoClientIdentifierKey | somehash123...               |
| Nation Slug     | NBInfoNationSlugKey       | abeforprez                   |
| Redirect Path   | NBInfoRedirectPathKey     | oauth/callback               |

__Note:__ `Nation Slug` isn't needed if you use NBAccountsManager. Other, optional
client info include:

|       Key       |        Key Constant       |         Sample Value         |
|-----------------|---------------------------|------------------------------|
| Base URL Format | NBInfoBaseURLFormatKey    | https://%@.nationbuilder.com |
| Test Token      | NBInfoTestTokenKey        | somehash123...               |

Note: `Test Token` is only needed if you turn on `shouldUseTestToken` for
the account. 

Note: `Base URL Format` is for internal use only. The URL format defaults to
the sample value (`NBClientDefaultBaseURLFormat`).

You can skip straight to [NBAccountButton][] if you're not planning to directly
manipulate NBAccount instances.

### Sign in

NBAccount's sign-in process builds on NBAuthenticator's methods. It ensures the
app is authorized and finds a credential with a valid access token for the
client. To make an account active, its underlying authenticator uses the token
flow. See [NBAuthenticator][] for details.

Upon getting the credential, the account also fetches the user info from the
`people/me` endpoint. With the user info, the account loads the avatar image
data, all before completing. So the account is populated with user data upon
sign-in.

```objectivec
// Continued.
[account requestActiveWithPriorSignout:NO completionHandler:^(NSError *error) {
    // This may be called immediately.
    if (error) {
        // Handle the error inside the completion block as you see fit.
        // ...
        return;
    }
    NBLog(@"Account name: %@, avatar: %@", self.name, self.avatarImageData);
}];
```

__Note:__ The account may activate immediately. This occurs if the credential is
already in the keychain and the authenticator can find it, or if the user data
is in memory.

__Note:__ The 'prior signout' flag is only used by NBAccountsManager, since signing
out of the current session in Safari is only necessary when using multiple
accounts.

### Sign out

NBAccount's sign-out process is simply ensuring the access token currently being
used is discarded (from both memory and disk). The account's client will no
longer be able to operate. An error will occur if discarding the credential
fails.

```objectivec
// Continued.
NSError *error;
BOOL didCleanUp = [account requestCleanUpWithError:&error];
if (!didCleanUp) {
    // Handle the error as you see fit.
    // ...
    return;
}
```

## NBAccountButton

NBAccount implements `NBAccountViewDataSource`, meaning it can be represented by
views. The SDK provides NBAccountButton as an all-purpose sign-in and sign-out
button that can adaptively display the account.

```objectivec
#import <NBClient/NBAccount.h>
#import <NBClient/UI/NBAccountButton.h>
// ...
NBAccountButton *accountButton = 
[NBAccountButton accountButtonFromNibWithTarget:self action:@selector(confirmSignOut:)];

NBAccount *account = [[NBAccount alloc] initWithClientInfo:nil delegate:self];
accountButton.dataSource = account;
// Or if you're also using NBAccountsManager:
// Initialize accounts manager...
accountButton.dataSources = accountsManager;
```

Note: For your account button, the action can be entirely custom and doesn't
need to be to start signing out.

In situations where there isn't a lot of space:

1. Using `NBAccountButtonTypeIconOnly`, you can just show icons that update
depending on the data source.
2. Using `NBAccountButtonTypeNameOnly`, you can just show the name text, which
will fall back to sign-in text.
3. Using `NBAccountButtonTypeAvatarOnly`, you can only show the avatar, which
will fall back to icons.

```objectivec
// Continued.
// Hip circular icons are supported too.
accountButton.shouldUseCircleAvatarFrame = YES;
// NBAccountButton also provides a UIBarButtonItem helper for easy placement in
// navigation bars and toolbars by automatically adjusting button type based on
// existing space.
UIBarButtonItem *buttonItem =
[accountButton barButtonItemWithCompactButtonType:NBAccountButtonTypeAvatarOnly];
[self.navigationItem setLeftBarButtonItem:buttonItem animated:YES];
```

When the user signs into the account, and when tapping on it subsequently signs
him out, the account button will update accordingly.

```objectivec
// Continued.
[account requestActiveWithPriorSignout:NO completionHandler:^(NSError *error) {
    // ...
    accountButton.dataSource = account;
}];
// ...
- (IBAction)confirmSignout:(id)sender {
  // Show an alert and confirm before signing out...
  NSError *error;
  BOOL didCleanUp = [account requestCleanUpWithError:&error];
  // ...
}
```

__Note:__ Using NBAccountButton by itself is only suitable if you only intend
the user to only use one account at any time, without ability to switch
accounts. It is much more common to use NBAccountsManager alongside
NBAccountsViewController, which will provide better functionality.

## NBAccountsManager

NBAccountsManager works with a collection of NBAccount's. It has the business
logic around an application's use and storage of multiple accounts from one or
more nations. It requires a delegate, implementing `NBAccountsManagerDelegate`,
to handle certain situations:

```objectivec
#import <NBClient/NBAccountsManager.h>

@interface MYAppDelegate () <NBAccountsManagerDelegate> @end
// Implement delegate methods...

NBAccountsManager *accountsManager =
[[NBAccountsManager alloc] initWithClientInfo:nil delegate:self];
```

__Note:__ The client info handling is the same as NBAccount, so passing nothing
just means the manager will default to the client info in the plist.

### Sign in

To sign into an account, the manager must know the nation slug for the account.
It will create the account and pass it the request to activate. (Then it will add
the account in good faith and remove it if activation fails.) It will pass any
errors to the delegate and will not add the same account twice.

```objectivec
// Continued.
NSError *error;
NSString *nationSlug = @"abeforprez"; // This would be user input.
BOOL didAdd = [accountsManager addAccountWithNationSlug:nationSlug error:&error];
if (!didAdd) {
    // Handle the error as you see fit.
}
```

Afterwards the delegate method for either a failed or successful account switch
will be called.

### Sign out

To sign out of an account, the manager will take the current `selectedAccount`
and request it to cleanup. If successful, it will remove the account. The
manager will turn off its `isSignedIn` flag if it has no more accounts to
select. Otherwise, it selects the first account.

```objectivec
// Continued.
error = nil;
BOOL didSignOut = [accountsManager signOutWithError:&error];
if (!didSignOut) {
    // Handle the error as you see fit.
}
if (!accountsManager.isSignedIn) {
    // Handle signing out of last account as you see fit.
}
```

__Note:__ Upon selecting an account, if the account's `isActive` flag is off,
the manager will attempt to reactivate the account.

## NBAccountsViewController

NBAccountsManager implements `NBAccountsViewDataSource`, meaning it can be
represented by views. The SDK provides NBAccountsViewController to both
represent NBAccountsManager and pass UI actions to it. 

```objectivec
#import <NBClient/NBAccountsManager.h>
#import <NBClient/UI/NBAccountsViewController.h>
//...
NBAccountsManager *accountsManager =
[[NBAccountsManager alloc] initWithClientInfo:nil delegate:self];

NBAccountsViewController *accountsViewController =
[[NBAccountsViewController alloc] initWithNibName:nil bundle:nil];
accountsViewController.dataSource = accountsManager;
self.accountsViewController = accountsViewController;
```

NBAccountsViewController will present an UIAlertView to prompt the user to enter
their nation slug. This happens automatically when the view controller appears.
To disable this behavior, turn off its `shouldAutoPromptForNationSlug` flag. You
can manually prompt the user by calling its `-promptForNationSlug`.

### Presentation

A common UX pattern is to present NBAccountsViewController when an
NBAccountButton gets tapped. NBAccountsViewController also provides a helper
method to make this simpler and universal. On normal device sizes, the view
controller is presented in a popover. In contrast on compact device sizes, the
view controller is presented in a full modal. Also note the view controller's
`-dismissViewControllerAnimated:completion:` has been modified to support this
helper.

```objectivec
// Continued.
// Set up an account button...
- (IBAction)presentAccountsViewController:(id)sender
{
    [self.accountsViewController showWithAccountButton:self.accountButton
                              presentingViewController:self];
}
```

__Note:__ However, there is an unorthodox inversion of responsibility here. A
view controller should not usually be able to present itself. You are also
welcome to write your own presentation logic for NBAccountsViewController.

## Delegation

Your app should respond to NBAccountsManager's state changes. It should provide
an `NBAccountsManagerDelegate` that properly implements certain methods.
Foremost, your app should refresh upon successful initial account activation and
further account switching. For example, in the sample app's app delegate:

```objectivec
- (void)accountsManager:(NBAccountsManager *)accountsManager didSwitchToAccount:(NBAccount *)account
{
    // If we have a new / different account.
    if (account) {
        // Clear out our data.
        self.peopleViewController.dataSource =
        [[NBPeopleViewDataSource alloc] initWithClient:account.client];
        // If the accounts view was shown to sign in initially, the user
        // probably just wants to start using the app.
        if (!self.peopleViewController.ready) {
            // Dismiss the accounts view if needed.
            [self.accountsViewController dismissViewControllerAnimated:YES completion:nil];
            // Set our view controller to ready to refresh it.
            self.peopleViewController.ready = YES;
        }
    // If we're no longer signed in, update our app.
    } else if (!account && !accountsManager.isSignedIn && self.peopleViewController.ready) {
        // Reset our view controller to the blank initial state.
        self.peopleViewController.ready = NO;
    }
}
```

Of course, how your app responds to account changes can vary depending on its
function.

### Handling Stale Tokens

If your client performs an operation with a stale API key (access token), the
NationBuilder API will return a 401 HTTP error. The accounts layer will prevent
default response handling and sign out of the current account with the stale
token. [NBAccount acts as a delegate for its client][NBClientDelegate] and will
handle this by tearing down itself. NBAccountsManager acts as a delegate for its
accounts, so it will further tear down the account.  And this HTTP error will
get passed from it to its delegate, which is ultimately your code implementing
the protocol. For example, in the sample app's app delegate:

```objectivec
- (void)accountsManager:(NBAccountsManager *)accountsManager didSignOutOfInvalidAccount:(NBAccount *)account
                                                                          fromHTTPError:(NSError *)error
{
    // Setting app to not ready and presenting accounts view for re-authenticating
    [self presentAccountsViewController:nil];
    self.peopleViewController.busy = NO;
}
```

## Notes

### Custom UI

Both NBAccountButton and NBAccountsViewController are both not required for use.
If you need UI that is more custom, you can write your own UI classes and just
use NBAccount and NBAccountsManager as data sources. Just make sure to not
include the default UI classes in your app. See the [installation
guide](installing selectively).

The UI classes provided by the SDK also use xib files. Custom attributes in the
xib configure the custom appearance-related properties on the view-related
classes.

### Appearance

View-related classes in the SDK, like NBAccountButton and
NBAccountsViewController, conform to the `UIAppearance` protocol. They support
custom styling with all their appearance-related properties. You shouldn't need
to use this support for these classes, but it's there if needed.

Remember you can also the [tint color API][] introduced in iOS 7

__[Next: Using Everything ➔](Using-Everything.md)__

[NBAuthenticator]: Using-the-Client.md#nbauthenticator
[NBAccountButton]: #nbaccountbutton
[NBClientDelegate]: Using-the-Client.md#custom-error-handling
[installing selectively]: Installing.md#selectively
[tint color API]: https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/TransitionGuide/AppearanceCustomization.html#//apple_ref/doc/uid/TP40013174-CH15-SW3
