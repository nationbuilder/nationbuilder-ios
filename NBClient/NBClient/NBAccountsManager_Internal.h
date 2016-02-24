//
//  NBAccountsManager_Internal.h
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import "NBAccountsManager.h"

@interface NBAccountsManager ()

@property (nonatomic, weak, readwrite, nullable) id<NBAccountsManagerDelegate> delegate;

// NBAccountsViewDataSource
@property (nonatomic, readwrite) BOOL signedIn;
@property (nonatomic, copy, readwrite, nullable) NSString *previousAccountNationSlug;

@property (nonatomic, readwrite) BOOL shouldPersistAccounts;

@property (nonatomic, copy, nonnull) NSDictionary *clientInfo;
@property (nonatomic, nonnull) NSMutableArray *mutableAccounts;

@property (nonatomic, nullable) id applicationDidBecomeActiveObserver;
@property (nonatomic, nullable) id applicationDidEnterBackgroundObserver;
@property (nonatomic, copy, nonnull) NSString *persistedAccountsIdentifier;

- (void)activateAccount:(nonnull NBAccount *)account;
- (void)deactivateAccount:(nonnull NBAccount *)account;
- (nonnull NSDictionary *)clientInfoForAccountWithNationSlug:(nonnull NSString *)nationSlug;
- (nonnull NBAccount *)createAccountWithNationSlug:(nonnull NSString *)nationSlug;

- (void)setUpAccountPersistence;
- (void)tearDownAccountPersistence;
- (void)loadPersistedAccounts;
- (void)persistAccounts;

@end
