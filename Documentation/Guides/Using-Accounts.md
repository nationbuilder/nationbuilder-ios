# Using Accounts

The accounts layer of the SDK is the top layer that we suggest you use. You can
use accounts to better represent users and user sessions. You can (and should)
additionally use account management to add multi-account, multi-nation support
in your app. Read on to learn more about the entire accounts layer.

## NBAccount

NBAccount is a model that builds upon the NBClient and NBAuthenticator and helps
your manage these components and acts as delegate for them when needed. It will
create them based on client info you provide. You can provide them during
initialization:

```objectivec
#import <NBClient/NBAccount.h>

@interface MYAppDelegate () <NBAccountDelegate> @end
// Implement delegate methods...

NBAccount *account = [[NBAccount alloc] initWithClientInfo:nil delegate:self];
```

Notice that passing client info during initialization is optional. If nothing is
provided, the account will look for the default client info in a file in your
application bundle called `NationBuilder-Info.plist`. Here is what you need to
put in the plist (or the dictionary):

|       Key       |        Key Constant       |         Sample Value         |
|-----------------|---------------------------|------------------------------|
| Client ID       | NBInfoClientIdentifierKey | somehash123...               |
| Nation Slug     | NBInfoNationSlugKey       | abeforprez                   |
| Redirect Path   | NBInfoRedirectPathKey     | oauth/callback               |

Note `Nation Slug` isn't needed if you use NBAccountsManager. Other, optional
client info include:

|       Key       |        Key Constant       |         Sample Value         |
|-----------------|---------------------------|------------------------------|
| Base URL Format | NBInfoBaseURLFormatKey    | https://%@.nationbuilder.com |
| Test Token      | NBInfoTestTokenKey        | somehash123...               |

Note that `Test Token` is only needed if you turn on `shouldUseTestToken` for
the account. Also note that `Base URL Format` is for internal use only; the URL
format defaults to the sample value (`NBClientDefaultBaseURLFormat`).

You can skip straight to [NBAccountButton][] if you're not planning to directly
manipulate NBAccount instances.

### Sign in

NBAccount's sign-in process is simply ensuring the app is authorized and finding
a credential with an access token that can be used by the client. To make an
account active, its underlying authenticator is used to authenticate using the
token flow. See [NBAuthenticator][] for details. In addition to getting the
credential, the account will also fetch the user info from the `people/me`
endpoint and the avatar image data, so the account is populated with user data
upon sign-in.

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

Depending on if the credential is already stored locally in the keychain and the
authenticator can find it, as well as if the user data is cached locally, the
account may activate immediately.

Note the 'prior signout' flag is only used by NBAccountsManager, since signing
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

(TODO: Update with account binding.)

```objectivec
#import <NBClient/NBAccount.h>
#import <NBClient/UI/NBAccountButton.h>
// ...
NBAccountButton *accountButton = 
[NBAccountButton accountButtonFromNibWithTarget:self action:@selector(confirmSignOut:)];

NBAccount *account = [[NBAccount alloc] initWithClientInfo:nil delegate:self];
accountButton.dataSource = account;
```

Note that for your account button, the action can be entirely custom and doesn't
need to be to start signing out.

In situations where there isn't a lot of space:

1. You can just show icons that update depending on the data source, using
`NBAccountButtonTypeIconOnly`.

2. You can just show the name text, which will fall back to sign-in text, using
`NBAccountButtonTypeNameOnly`.

3. You can only show the avatar, which will fall back to icons, using
`NBAccountButtonTypeAvatarOnly`.

```objectivec
// Continued.
if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
    accountButton.buttonType = NBAccountButtonTypeAvatarOnly;
}
// Hip circular icons are supported too.
accountButton.shouldUseCircleAvatarFrame = YES;
// NBAccountButton also provides a UIBarButtonItem helper for easy placement in
// navigation bars and toolbars.
[self.navigationItem setLeftBarButtonItem:accountButton.barButtonItem animated:YES];
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

Using NBAccountButton by itself is only suitable if you only intend the user to
only use one account at any time. It is much more common to use
NBAccountsManager alongside NBAccountsViewController, which will provide better
functionality.

## NBAccountsManager

NBAccountsManager works with a collection of NBAccount's. It handles the
business logic around an application's use and storage of multiple accounts from
one or more nations. It requires a delegate, implementing
`NBAccountsManagerDelegate`, to handle certain situations:

```objectivec
#import <NBClient/NBAccountsManager.h>

@interface MYAppDelegate () <NBAccountsManagerDelegate> @end
// Implement delegate methods...

NBAccountsManager *accountsManager =
[[NBAccountsManager alloc] initWithClientInfo:nil delegate:self];
```

Note the client info handling is the same as NBAccount, so passing nothing just
means the manager will default to the client info in the plist.

### Sign in

To sign into an account, the manager must know the nation slug for the account.
It will create the account and pass it the request to activate. Then it will add
the account in good faith and remove it if activation fails. It will pass any
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
and pass the cleanup request for the account to handle. If successful, it will
remove the account. The manager will turn off its `signedIn` flag if it has no
more accounts to select. Otherwise, the first account is selected.

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

Note that when an account is selected, if the account's active flag is off, the
manager will attempt to reactivate the account.

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
their nation slug. This happens automatically when it appears. To disable this
behavior, turn off `shouldAutoPromptForNationSlug`. You can manually prompt the
user by calling `-promptForNationSlug`.

A common UX pattern is to present NBAccountsViewController when an
NBAccountButton gets tapped. NBAccountsViewController also provides a helper
method to make this simpler and universal. On normal device sizes, the view
controller is presented in a popover, while on compact device sizes, the view
controller is presented in a full modal. Also note  NBAccountsViewController's
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

However, note the unorthodox inversion of control here. A view controller should
not usually be able to present itself. You are also welcome to write your own
presentation logic for NBAccountsViewController.

## Delegation

Your app should respond to NBAccountsManager's state changes by providing a
delegate that properly implements certain methods. Foremost, your app should
refresh upon successful initial account activation and further account
switching. For example, in the sample app's app delegate:

```objectivec
- (void)accountsManager:(NBAccountsManager *)accountsManager didSwitchToAccount:(NBAccount *)account
{
    // Update the account button.
    self.accountButton.dataSource = account;
    self.accountButton.contextHasMultipleActiveAccounts = self.accountsManager.accounts.count > 1;
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
default response handling and sign out of the current account that's using the
stale token. [NBAccount acts as a delegate for its client][NBClientDelegate] and
will handle this by tearing down itself. NBAccountsManager acts as a delegate
for its accounts, so it will further tear down the account, and this HTTP error
will get passed from it to its delegate, which is ultimately your code
implementing the protocol. For example, in the sample app's app delegate:

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
If you need UI that is more custom, you can write your own UI classes and simply
use NBAccount and NBAccountsManager as data sources. Just make sure to not
include the default UI classes in your app.

(TODO: How to only use the core and not the UI.)

The UI classes provided by the SDK also use xib files. Custom appearance-related
properties on the view and view controller classes are set using the custom
attributes part of the xib.

### Appearance

Both NBAccountButton and NBAccountsViewController, like other view-related
classes in the SDK, support custom styling via `UIAppearance` with all of their
appearance-related properties. You shouldn't need to use this support for these
classes, but it's there if needed.

__[Next: Using Everything ➔](Using-Everything.md)__

[NBAuthenticator]: Using-the-Client.md#nbauthenticator
[NBAccountButton]: #nbaccountbutton
[NBClientDelegate]: Using-the-Client.md#custom-error-handling
