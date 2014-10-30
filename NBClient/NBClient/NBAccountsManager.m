//
//  NBAccountsManager.m
//  NBClient
//
//  Created by Peng Wang on 10/9/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBAccountsManager.h"

#import <UIKit/UIKit.h>

#import "FoundationAdditions.h"
#import "NBAccount.h"

NSString * const NBAccountInfosDefaultsKey = @"NBAccountInfos";
NSString * const NBAccountInfoIdentifierKey = @"User ID";
NSString * const NBAccountInfoNameKey = @"User Name";
NSString * const NBAccountInfoNationSlugKey = @"Nation Slug";

#if DEBUG
static NBLogLevel LogLevel = NBLogLevelDebug;
#else
static NBLogLevel LogLevel = NBLogLevelWarning;
#endif

@interface NBAccountsManager ()

@property (nonatomic, weak, readwrite) id<NBAccountsManagerDelegate> delegate;

// NBAccountsViewDataSource
@property (nonatomic, readwrite) BOOL signedIn;
@property (nonatomic, strong, readwrite) NSString *previousAccountNationSlug;

@property (nonatomic, strong) NSDictionary *clientInfo;
@property (nonatomic, strong) NSMutableArray *mutableAccounts;

@property (nonatomic) BOOL shouldPersistAccounts;
@property (nonatomic, strong) id applicationDidEnterBackgroundNotifier;
@property (nonatomic, strong) NSString *persistedAccountsIdentifier;

- (void)activateAccount:(NBAccount *)account;
- (void)deactivateAccount:(NBAccount *)account;
- (NSDictionary *)clientInfoForAccountWithNationSlug:(NSString *)nationSlug;

- (void)setUpAccountPersistence;
- (void)tearDownAccountPersistence;
- (void)loadPersistedAccounts;
- (void)persistAccounts;

@end

@implementation NBAccountsManager

- (instancetype)initWithClientInfo:(NSDictionary *)clientInfoOrNil
                          delegate:(id<NBAccountsManagerDelegate>)delegate
{
    self = [super init];
    if (self) {
        NSAssert(delegate, @"A delegate is required.");
        self.delegate = delegate;
        self.clientInfo = clientInfoOrNil;
        self.mutableAccounts = [NSMutableArray array];
        [self setUpAccountPersistence];
        [self loadPersistedAccounts];
    }
    return self;
}

#pragma mark - NBLogging

+ (void)updateLoggingToLevel:(NBLogLevel)logLevel
{
    LogLevel = logLevel;
    [NBAccount updateLoggingToLevel:logLevel];
}

#pragma mark - NBAccountsDataSource

- (NSArray *)accounts
{
    return [NSArray arrayWithArray:self.mutableAccounts];
}

@synthesize selectedAccount = _selectedAccount;

- (void)setSelectedAccount:(id<NBAccountViewDataSource>)selectedAccount
{
    // Guard.
    if (selectedAccount == self.selectedAccount) { return; }
    // Will.
    NBAccount *account;
    if (selectedAccount) {
        account = (NBAccount *)selectedAccount;
    } else if (self.selectedAccount) {
        self.previousAccountNationSlug = self.selectedAccount.nationSlug;
    }
    if (account && !account.isActive) {
        // Activate if needed.
        [self activateAccount:account];
        return; // Defer.
    }
    if ([self.delegate respondsToSelector:@selector(accountsManager:willSwitchToAccount:)]) {
        [self.delegate accountsManager:self willSwitchToAccount:account];
    }
    // Set.
    _selectedAccount = selectedAccount;
    // Did.
    if ([self.delegate respondsToSelector:@selector(accountsManager:didSwitchToAccount:)]) {
        [self.delegate accountsManager:self didSwitchToAccount:account];
    }
}

- (BOOL)addAccountWithNationSlug:(NSString *)nationSlug error:(NSError *__autoreleasing *)error
{
    BOOL isValid = YES;
    NSString *failureReason;
    if (!nationSlug) {
        failureReason = @"message.invalid-nation-slug.none".nb_localizedString;
    }
    nationSlug = [nationSlug stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!failureReason && !nationSlug.length) {
        failureReason = @"message.invalid-nation-slug.empty".nb_localizedString;
    }
    if (failureReason) {
        isValid = NO;
        *error = [NSError errorWithDomain:NBErrorDomain code:NBErrorCodeInvalidArgument
                                userInfo:@{ NSLocalizedDescriptionKey: @"message.invalid-nation-slug".nb_localizedString,
                                            NSLocalizedFailureReasonErrorKey: failureReason }];
    } else {
        NBAccount *account = [[NBAccount alloc] initWithClientInfo:
                              [self clientInfoForAccountWithNationSlug:nationSlug]];
        if (!self.clientInfo) {
            NSMutableDictionary *mutableClientInfo = account.clientInfo.mutableCopy;
            [mutableClientInfo removeObjectForKey:NBInfoNationNameKey];
            self.clientInfo = [NSDictionary dictionaryWithDictionary:mutableClientInfo];
        }
        if ([self.delegate respondsToSelector:@selector(accountsManager:willAddAccount:)]) {
            [self.delegate accountsManager:self willAddAccount:account];
        }
        [self.mutableAccounts addObject:account];
        [self activateAccount:account];
    }
    return isValid;
}

- (BOOL)signOutWithError:(NSError *__autoreleasing *)error
{
    BOOL didSignOut = NO;
    NBAccount *account = (id)self.selectedAccount;
    NSAssert(account, @"No active account found.");
    if (!account) { return didSignOut; }
    BOOL didCleanUp = [account requestCleanUpWithError:error];
    if (didCleanUp) {
        [self deactivateAccount:account];
        didSignOut = YES;
    }
    return didSignOut;
}

#pragma mark - Private

- (void)activateAccount:(NBAccount *)account
{
    BOOL needsPriorSignout = self.selectedAccount && [self.selectedAccount.nationSlug isEqualToString:account.nationSlug];
    [account requestActiveWithPriorSignout:needsPriorSignout completionHandler:^(NSError *error) {
        BOOL shouldBail = NO;
        if (error) {
            [self.mutableAccounts removeObject:account];
            [self.delegate accountsManager:self didFailToSwitchToAccount:account withError:error];
            shouldBail = YES;
        } else {
            for (NBAccount *existingAccount in self.accounts) {
                if (existingAccount != account && existingAccount.identifier == account.identifier) {
                    shouldBail = YES;
                    break;
                }
            }
            if (shouldBail) {
                [self.mutableAccounts removeObject:account];
                NBLogWarning(@"User attempted to activate duplicate account with identifier %lu",
                             account.identifier);
            }
        }
        if (shouldBail) {
            if (!self.selectedAccount && self.mutableAccounts.count) {
                // Try again with another account if needed and possible.
                [self activateAccount:self.mutableAccounts.firstObject];
            }
            return;
        }
        self.selectedAccount = account;
        if (!self.isSignedIn) {
            self.signedIn = YES;
        }
    }];
}

- (void)deactivateAccount:(NBAccount *)account
{
    [self.mutableAccounts removeObject:account];
    if (!self.accounts.count && self.isSignedIn) {
        self.signedIn = NO;
    }
    // Switch to first available account, if any.
    self.selectedAccount = self.accounts.firstObject;
}

- (NSDictionary *)clientInfoForAccountWithNationSlug:(NSString *)nationSlug
{
    NSMutableDictionary *mutableClientInfo = self.clientInfo ? self.clientInfo.mutableCopy : [NSMutableDictionary dictionary];
    mutableClientInfo[NBInfoNationNameKey] = nationSlug;
    return [NSDictionary dictionaryWithDictionary:mutableClientInfo];
}

#pragma mark Account Persistence

- (void)setUpAccountPersistence
{
    // Guard.
    self.shouldPersistAccounts = YES;
    if ([self.delegate respondsToSelector:@selector(accountsManagerShouldPersistAccounts:)]) {
        self.shouldPersistAccounts = [self.delegate accountsManagerShouldPersistAccounts:self];
    }
    if (!self.shouldPersistAccounts) { return; }
    // Continue.
    if ([self.delegate respondsToSelector:@selector(persistedAccountsIdentifierForAccountsManager:)]) {
        self.persistedAccountsIdentifier = [self.delegate persistedAccountsIdentifierForAccountsManager:self];
    }
    self.persistedAccountsIdentifier = (self.persistedAccountsIdentifier
                                        ?: [NSString stringWithFormat:@"%@-%@",
                                            NBAccountInfosDefaultsKey, NSStringFromClass(self.delegate.class)]);
    __weak __typeof(self)weakSelf = self;
    self.applicationDidEnterBackgroundNotifier =
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIApplicationDidEnterBackgroundNotification
     object:[UIApplication sharedApplication] queue:[NSOperationQueue mainQueue]
     usingBlock:^(NSNotification *note) {
         NSAssert(weakSelf, @"Account manager dereferenced before application received termination signal.");
         [weakSelf persistAccounts];
     }];
}

- (void)tearDownAccountPersistence
{
    if (!self.shouldPersistAccounts) { return; }
    [[NSNotificationCenter defaultCenter] removeObserver:self.applicationDidEnterBackgroundNotifier];
}

- (void)loadPersistedAccounts
{
    if (!self.shouldPersistAccounts) { return; }
    NSArray *accountInfos = [[NSUserDefaults standardUserDefaults] arrayForKey:self.persistedAccountsIdentifier];
    if (accountInfos) {
        for (NSDictionary *accountInfo in accountInfos) {
            NBAccount *account = [[NBAccount alloc] initWithClientInfo:
                                  [self clientInfoForAccountWithNationSlug:accountInfo[NBAccountInfoNationSlugKey]]];
            account.name = accountInfo[NBAccountInfoNameKey];
            account.identifier = [accountInfo[NBAccountInfoIdentifierKey] unsignedIntegerValue];
            [self.mutableAccounts addObject:account];
        }
        [self activateAccount:self.accounts.firstObject];
        NBLogInfo(@"Loaded %lu persisted account(s) for identifier \"%@\"",
                  accountInfos.count, self.persistedAccountsIdentifier);
    }
}

- (void)persistAccounts
{
    if (!self.shouldPersistAccounts) { return; }
    NSMutableArray *accountInfos = [NSMutableArray array];
    for (NBAccount *account in self.accounts) {
        if (!account.name) { continue; }
        [accountInfos addObject:@{ NBAccountInfoIdentifierKey: @(account.identifier),
                                   NBAccountInfoNameKey: account.name,
                                   NBAccountInfoNationSlugKey: account.nationSlug }];
    }
    [[NSUserDefaults standardUserDefaults] setObject:accountInfos forKey:self.persistedAccountsIdentifier];
    NBLogInfo(@"Persisted %lu persisted account(s) for identifier \"%@\"",
              accountInfos.count, self.persistedAccountsIdentifier);
}

@end