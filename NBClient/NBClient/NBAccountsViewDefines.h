//
//  NBAccountsViewDefines.h
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NBAccount;
@class NBAccountsManager;

@protocol NBAccountViewDataSource;

// An account manager must have a delegate. That delegate must implement the
// methods to handle errors from the account management process.
@protocol NBAccountsManagerDelegate <NSObject>

// This delegate method should be implemented to handle any errors from the
// account switching process. The error can be presented in the UI and has text for
// keys: `NSLocalizedDescriptionKey`, `NSLocalizedFailureReasonErrorKey`, and
// `NSLocalizedRecoverySuggestionErrorKey`.
- (void)accountsManager:(nonnull NBAccountsManager *)accountsManager didFailToSwitchToAccount:(nonnull NBAccount *)account withError:(nullable NSError *)error;
// This delegate method should be implemented to handle cases when an account is
// discovered to be invalid, ie. from the failure of a client's request. Simply
// updating the UI and presenting the accounts view again is enough.
- (void)accountsManager:(nonnull NBAccountsManager *)accountsManager didSignOutOfInvalidAccount:(nonnull NBAccount *)account fromHTTPError:(nonnull NSError *)error;

@optional

// Implement this delegate method and return `NO` to disable account
// persistence, which is enabled by default.
- (BOOL)accountsManagerShouldPersistAccounts:(nonnull NBAccountsManager *)accountsManager;
// NOTE: Accounts persistence does not support all configurations by default.
// Multiple instance properties of account managers is not supported. Neither is
// multiple instances of a class with an account manager property. Set this
// property to customize.
- (nonnull NSString *)persistedAccountsIdentifierForAccountsManager:(nonnull NBAccountsManager *)accountsManager;

// This delegate method is called before the manager adds registers the account
// and attempts to activate it if needed.
- (void)accountsManager:(nonnull NBAccountsManager *)accountsManager willAddAccount:(nonnull NBAccount *)account;
// This delegate method is called before the manager sets its `selectedAccount`.
// The new account may be nil if no to-account is specified for the switch, ie. on
// signout of selected account.
- (void)accountsManager:(nonnull NBAccountsManager *)accountsManager willSwitchToAccount:(nullable NBAccount *)account;
// This delegate method is called after the manager sets its `selectedAccount`.
// The new account may be nil if no to-account is specified for the switch, ie. on
// signout of selected account. Otherwise the account should be valid and active.
// If you're using an account button you should update its data source with the
// new account.
- (void)accountsManager:(nonnull NBAccountsManager *)accountsManager didSwitchToAccount:(nullable NBAccount *)account;

@end

// The account manager also acts as a view's data source and implements this
// protocol. The view can link actions to the data source for account sign-in
// (`-addAccountWithNationSlug:error:`) and sign-out (`-signOutWithError:`).
@protocol NBAccountsViewDataSource <NSObject>

@property (nonatomic, copy, readonly, nonnull) NSArray *accounts;
@property (nonatomic, copy, readonly, nullable) NSString *previousAccountNationSlug;
// Setting this triggers the process for switching to the provided account. Do
// not pass nil to sign out of the selected account. Instead call
// `-signOutWithError:`.
@property (nonatomic, nullable) id<NBAccountViewDataSource> selectedAccount;

@property (nonatomic, readonly, getter = isSignedIn) BOOL signedIn;

// The errors created by the following methods can be presented in the UI and
// has text for keys: `NSLocalizedDescriptionKey`,
// `NSLocalizedFailureReasonErrorKey`, and `NSLocalizedRecoverySuggestionErrorKey`.

// This process will not complete synchronously. A non-nil error and `NO` get
// returned if initial validations fail. Refer to the methods in
// `NBAccountsManagerDelegate`.
- (BOOL)addAccountWithNationSlug:(nonnull NSString *)nationSlug error:(NSError * __nullable * __nullable)error;
// This process will complete synchronously.
- (BOOL)signOutWithError:(NSError * __nullable * __nullable)error;

@end

// These are the properties of an account that are available to be presented by
// any account view, ie. the account button.
@protocol NBAccountViewDataSource <NSObject>

@property (nonatomic, copy, readonly, nonnull) NSString *name; // `username`, otherwise `full_name`
@property (nonatomic, copy, readonly, nonnull) NSString *nationSlug;
@property (nonatomic, nullable) NSData *avatarImageData; // Set to nil to clear memory.

@end
