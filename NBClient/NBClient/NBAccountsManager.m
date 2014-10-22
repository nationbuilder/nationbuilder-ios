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
NSString * const NBAccountInfoNationSlugKey = @"Nation Slug";
NSString * const NBAccountInfoNameKey = @"User Name";

@interface NBAccountsManager ()

@property (nonatomic, readwrite) BOOL signedIn;

@property (nonatomic, strong) NSDictionary *clientInfo;
@property (nonatomic, strong) NSMutableArray *mutableAccounts;

@property (nonatomic, strong) id applicationWillTerminateObserver;

- (void)activateAccount:(NBAccount *)account;
- (void)deactivateAccount:(NBAccount *)account;
- (NSDictionary *)clientInfoForAccountWithNationSlug:(NSString *)nationSlug;

- (void)setUpAccountPersistence;
- (void)tearDownAccountPersistence;
- (void)persistAccounts;

@end

@implementation NBAccountsManager

- (instancetype)initWithClientInfo:(NSDictionary *)clientInfoOrNil
{
    self = [super init];
    if (self) {
        self.shouldPersistAccounts = YES;
        self.clientInfo = clientInfoOrNil;
        self.mutableAccounts = [NSMutableArray array];
        [self setUpAccountPersistence];
    }
    return self;
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
    }
    if (account && !account.isActive) {
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
    NBAccount *account = self.selectedAccount;
    NSAssert(account, @"No active account found.");
    if (!account) { return didSignOut; }
    BOOL didCleanUp = [account requestCleanUpWithError:error];
    if (didCleanUp) {
        [self deactivateAccount:self.selectedAccount];
        didSignOut = YES;
    }
    return didSignOut;
}

#pragma mark - Private

- (void)activateAccount:(NBAccount *)account
{
    [account requestActiveWithCompletionHandler:^(NSError *error) {
        if (error) {
            [self.delegate accountsManager:self failedToSwitchToAccount:account withError:error];
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
    self.selectedAccount = nil;
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
    if (!self.shouldPersistAccounts) { return; }
    NSArray *accountInfos = [[NSUserDefaults standardUserDefaults] arrayForKey:NBAccountInfosDefaultsKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:NBAccountInfosDefaultsKey];
    if (accountInfos) {
        for (NSDictionary *accountInfo in accountInfos) {
            NBAccount *account = [[NBAccount alloc] initWithClientInfo:
                                  [self clientInfoForAccountWithNationSlug:accountInfo[NBAccountInfoNationSlugKey]]];
            account.name = accountInfo[NBAccountInfoNameKey];
            [self.mutableAccounts addObject:account];
            if (!self.selectedAccount) {
                [self activateAccount:account];
            }
        }
    }
    __weak __typeof(self)weakSelf = self;
    self.applicationWillTerminateObserver =
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIApplicationWillTerminateNotification
     object:[UIApplication sharedApplication] queue:[NSOperationQueue mainQueue]
     usingBlock:^(NSNotification *note) {
         NSAssert(weakSelf, @"Account manager dereferenced before application received termination signal.");
         [weakSelf persistAccounts];
     }];
}

- (void)tearDownAccountPersistence
{
    if (!self.shouldPersistAccounts) { return; }
    [[NSNotificationCenter defaultCenter] removeObserver:self.applicationWillTerminateObserver];
}

- (void)persistAccounts
{
    if (!self.shouldPersistAccounts) { return; }
    NSMutableArray *accountInfos = [NSMutableArray array];
    for (NBAccount *account in self.accounts) {
        [accountInfos addObject:@{ NBAccountInfoNameKey: account.name,
                                   NBAccountInfoNationSlugKey: account.nationSlug }];
    }
    [[NSUserDefaults standardUserDefaults] setObject:accountInfos forKey:NBAccountInfosDefaultsKey];
}

@end