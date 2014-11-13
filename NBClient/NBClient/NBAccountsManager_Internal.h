//
//  NBAccountsManager_Internal.h
//  NBClient
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBAccountsManager.h"

@interface NBAccountsManager ()

@property (nonatomic, weak, readwrite) id<NBAccountsManagerDelegate> delegate;

// NBAccountsViewDataSource
@property (nonatomic, readwrite) BOOL signedIn;
@property (nonatomic, strong, readwrite) NSString *previousAccountNationSlug;

@property (nonatomic, readwrite) BOOL shouldPersistAccounts;

@property (nonatomic, strong) NSDictionary *clientInfo;
@property (nonatomic, strong) NSMutableArray *mutableAccounts;

@property (nonatomic, strong) id applicationDidEnterBackgroundNotifier;
@property (nonatomic, strong) NSString *persistedAccountsIdentifier;

- (void)activateAccount:(NBAccount *)account;
- (void)deactivateAccount:(NBAccount *)account;
- (NSDictionary *)clientInfoForAccountWithNationSlug:(NSString *)nationSlug;
- (NBAccount *)createAccountWithNationSlug:(NSString *)nationSlug;

- (void)setUpAccountPersistence;
- (void)tearDownAccountPersistence;
- (void)loadPersistedAccounts;
- (void)persistAccounts;

@end
