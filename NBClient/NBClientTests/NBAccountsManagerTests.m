//
//  NBAccountsManagerTests.m
//  NBClient
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBTestCase.h"

#import <UIKit/UIKit.h>

#import "NBAccount_Internal.h"
#import "NBAccountsManager.h"
#import "NBAccountsManager_Internal.h"

@interface NBAccountsManagerTests : NBTestCase

@property (nonatomic) NBAccountsManager *accountsManager;

@property (nonatomic) id accountMock;
@property (nonatomic) id accountsManagerMock;
@property (nonatomic) id delegateMock;

- (NBAccount *)createAccount;

- (id)createAccountMock;
- (void)populateAccountsManagerWithAccountMocks:(NBAccountsManager *)accountsManager;
- (void)performAccountPersistenceWithAccountsManager:(NBAccountsManager *)accountsManager;

- (void)assertAccountsManagerDeactivatedAccountAndIsSignedOut;

@end

@implementation NBAccountsManagerTests

#pragma mark - Helpers

- (NBAccountsManager *)accountsManager
{
    if (_accountsManager) {
        return _accountsManager;
    }
    self.accountsManager = [[NBAccountsManager alloc] initWithClientInfo:nil delegate:self.delegateMock];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.accountsManager.persistedAccountsIdentifier];
    return _accountsManager;
}

- (id)accountMock
{
    if (_accountMock) {
        return _accountMock;
    }
    self.accountMock = [self createAccountMock];
    return _accountMock;
}

- (id)accountsManagerMock
{
    if (_accountsManagerMock) {
        return _accountsManagerMock;
    }
    self.accountsManagerMock = OCMPartialMock(self.accountsManager);
    return _accountsManagerMock;
}

- (id)delegateMock
{
    if (_delegateMock) {
        return _delegateMock;
    }
    self.delegateMock = OCMProtocolMock(@protocol(NBAccountsManagerDelegate));
    [OCMStub([self.delegateMock persistedAccountsIdentifierForAccountsManager:OCMOCK_ANY]) andReturn:@"somename"];
    return _delegateMock;
}

- (NBAccount *)createAccount
{
    __block NBAccount *account;
    [self stubInfoFileBundleResourcePathForOperations:^{
        account = [[NBAccount alloc] initWithClientInfo:nil delegate:self.accountsManagerMock];
    }];
    return account;
}

- (id)createAccountMock
{
    // NOTE: We're not partial mocking this because its functionality is not this layer's concern.
    id accountMock = OCMClassMock([NBAccount class]);
    [OCMStub([accountMock requestActiveWithPriorSignout:NO completionHandler:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        [OCMStub([accountMock isActive]) andReturnValue:@YES];
        NBGenericCompletionHandler completionHandler;
        [invocation getArgument:&completionHandler atIndex:3];
        [invocation retainArguments];
        completionHandler(nil);
    }];
    return accountMock;
}

- (void)populateAccountsManagerWithAccountMocks:(NBAccountsManager *)accountsManager
{
    [accountsManager.mutableAccounts addObjectsFromArray:@[ [self createAccountMock], [self createAccountMock] ]];
    NSUInteger identifier = 123;
    for (NBAccount *account in accountsManager.accounts) {
        [OCMStub([account identifier]) andReturnValue:@(identifier++)];
        [OCMStub([account name]) andReturn:@"someusername"];
        [OCMStub([account nationSlug]) andReturn:self.nationSlug];
    }
}

- (void)performAccountPersistenceWithAccountsManager:(NBAccountsManager *)accountsManager
{
    [accountsManager persistAccounts];
    accountsManager.mutableAccounts = [NSMutableArray array];
    [accountsManager loadPersistedAccounts];
}

- (void)assertAccountsManagerDeactivatedAccountAndIsSignedOut
{
    NBAccountsManager *accountsManager = self.accountsManagerMock;
    XCTAssertNil(accountsManager.selectedAccount,
                 @"Manager should not have a selected account.");
    XCTAssertFalse(accountsManager.isSignedIn,
                   @"Manager should not be signed in.");
    XCTAssertEqual(accountsManager.accounts.count, 0,
                   @"Manager should have no more accounts.");
}

#pragma mark - Tests

- (void)testDefaultInitialization
{
    NBAccountsManager *accountsManager = self.accountsManager; // NOTE: Initializes.
    XCTAssertEqualObjects(accountsManager.accounts, @[],
                          @"Manager's accounts should never be nil.");
}

- (void)testAccountSelectionAndDelegateDidSwitchToAccount
{
    NBAccountsManager *accountsManager = self.accountsManager;
    // Given: accounts manager has an active account.
    NBAccount *account = [self createAccount];
    account.active = YES;
    // Add it just to be safe.
    [accountsManager.mutableAccounts addObject:account];
    // When.
    accountsManager.selectedAccount = account;
    // Then.
    XCTAssertEqual(accountsManager.selectedAccount, account,
                   @"New account should be selected.");
    // Then: delegate method should be called and passed account.
    OCMVerify([self.delegateMock accountsManager:accountsManager willSwitchToAccount:account]);
    OCMVerify([self.delegateMock accountsManager:accountsManager didSwitchToAccount:account]);
}

- (void)testAccountAdditionAndDelegateWillAddAccount
{
    NBAccountsManager *accountsManager = self.accountsManagerMock;
    // Given: an invalid nation slug.
    NSString *invalidNationSlug = @"";
    // When: adding with an invalid nation slug.
    __block NSError *error;
    __block BOOL didAdd = [accountsManager addAccountWithNationSlug:invalidNationSlug error:&error];
    // Then.
    XCTAssertNotNil(error, @"Validation error should be set.");
    XCTAssertFalse(didAdd, @"Nothing should be added.");
    error = nil;

    // Given: an account that can properly activate.
    NBAccount *account = self.accountMock;
    // When: adding with a valid nation slug and given available info file.
    [self stubInfoFileBundleResourcePathForOperations:^{
        [OCMStub([accountsManager createAccountWithNationSlug:OCMOCK_ANY]) andReturn:account];
        didAdd = [accountsManager addAccountWithNationSlug:self.nationSlug error:&error];
    }];
    // Then: account is added, selected, and changes manager to being signed-in.
    XCTAssertNil(error, @"Error should not be set.");
    XCTAssertTrue(didAdd, @"Account should be added.");
    XCTAssertTrue([accountsManager.accounts containsObject:account],
                  @"Account should be in manager's accounts.");
    XCTAssertTrue(accountsManager.isSignedIn,
                  @"Manager should be signed in.");
    XCTAssertEqual(accountsManager.selectedAccount, account,
                   @"New account should be selected.");
    // Then: delegate methods are called with account.
    OCMVerify([self.delegateMock accountsManager:self.accountsManager willAddAccount:account]);
    OCMVerify([self.delegateMock accountsManager:self.accountsManager didSwitchToAccount:account]);
}

- (void)testDuplicateAccountAddition
{
    NBAccountsManager *accountsManager = self.accountsManagerMock;
    // Given: manager has populated accounts.
    [self populateAccountsManagerWithAccountMocks:accountsManager];
    accountsManager.selectedAccount = accountsManager.accounts.lastObject;
    // Given: a duplicate account that has the same identifier.
    NBAccount *duplicate = self.accountMock;
    [OCMStub([duplicate identifier]) andReturnValue:@([(NBAccount *)accountsManager.selectedAccount identifier])];
    // When.
    NSUInteger originalCount = accountsManager.accounts.count;
    [self stubInfoFileBundleResourcePathForOperations:^{
        [OCMStub([accountsManager createAccountWithNationSlug:OCMOCK_ANY]) andReturn:duplicate];
        [accountsManager addAccountWithNationSlug:self.nationSlug error:nil];
    }];
    // Then: account is not added.
    XCTAssertEqual(accountsManager.accounts.count, originalCount);
    XCTAssertFalse([accountsManager.accounts containsObject:duplicate],
                   @"Account should not be in manager's accounts.");
}

- (void)testInvalidAccountAdditionAndDelegateDidFailToSwitchToAccount
{
    NBAccountsManager *accountsManager = self.accountsManagerMock;
    // Given: an account that can't properly activate.
    id accountMock = OCMClassMock([NBAccount class]);
    NSError *error = [NSError errorWithDomain:NBErrorDomain code:0 userInfo:nil];
    [OCMStub([accountMock requestActiveWithPriorSignout:NO completionHandler:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        NBGenericCompletionHandler completionHandler;
        [invocation getArgument:&completionHandler atIndex:3];
        [invocation retainArguments];
        completionHandler(error);
    }];
    // When.
    [self stubInfoFileBundleResourcePathForOperations:^{
        [OCMStub([accountsManager createAccountWithNationSlug:OCMOCK_ANY]) andReturn:accountMock];
        [accountsManager addAccountWithNationSlug:self.nationSlug error:nil];
    }];
    // Then.
    XCTAssertFalse([accountsManager.accounts containsObject:accountMock],
                   @"Account should not be in manager's accounts.");
    // Then: delegate method is called with account and error.
    OCMVerify([self.delegateMock accountsManager:self.accountsManager didFailToSwitchToAccount:accountMock withError:error]);
}

- (void)testSelectedAccountSignOut
{
    NBAccountsManager *accountsManager = self.accountsManagerMock;
    // Given: two accounts are active and the last one is selected.
    id accountMock = [self createAccountMock];
    id otherAccountMock = [self createAccountMock];
    [OCMStub([(NBAccount *)accountMock identifier]) andReturnValue:@123];
    [OCMStub([(NBAccount *)otherAccountMock identifier]) andReturnValue:@321];
    [self stubInfoFileBundleResourcePathForOperations:^{
        [OCMStub([accountsManager createAccountWithNationSlug:self.nationSlug]) andReturn:accountMock];
        [accountsManager addAccountWithNationSlug:self.nationSlug error:nil];
        [OCMStub([accountsManager createAccountWithNationSlug:@"othernation"]) andReturn:otherAccountMock];
        [accountsManager addAccountWithNationSlug:@"othernation" error:nil];
    }];
    // Given: accounts can be properly cleaned up.
    [OCMStub([accountMock requestCleanUpWithError:[OCMArg anyObjectRef]]) andReturnValue:@YES];
    [OCMStub([otherAccountMock requestCleanUpWithError:[OCMArg anyObjectRef]]) andReturnValue:@YES];
    // When: signing out of most recent account.
    NSError *error;
    BOOL didSignOut = [accountsManager signOutWithError:&error];
    // Then: signout should be successful.
    XCTAssertNil(error, @"Error should not be set.");
    XCTAssertTrue(didSignOut, @"Signout should be successful.");
    error = nil;
    // Then: manager is signed-into the first account.
    XCTAssertEqual(accountsManager.selectedAccount, accountMock,
                   @"First account should be selected.");
    XCTAssertTrue(accountsManager.isSignedIn,
                  @"Manager should still be signed in.");
    XCTAssertFalse([accountsManager.accounts containsObject:otherAccountMock],
                   @"Second account should not be in manager's accounts.");
    // When: signing out of remaining account.
    didSignOut = [accountsManager signOutWithError:&error];
    // Then: signout should be successful.
    XCTAssertNil(error, @"Error should not be set.");
    XCTAssertTrue(didSignOut, @"Signout should be successful.");
    // Then: manager is no longer signed-in.
    [self assertAccountsManagerDeactivatedAccountAndIsSignedOut];
}

- (void)testDelegateDidSignOutOfInvalidAccount
{
    NBAccountsManager *accountsManager = self.accountsManagerMock;
    // Given: an account that is added, active, and selected.
    NBAccount *account = self.accountMock;
    [self stubInfoFileBundleResourcePathForOperations:^{
        [OCMStub([accountsManager createAccountWithNationSlug:OCMOCK_ANY]) andReturn:account];
        [accountsManager addAccountWithNationSlug:self.nationSlug error:nil];
    }];
    // When: account becomes invalid and calls delegate method.
    NSError *error = [NSError errorWithDomain:NBErrorDomain code:0 userInfo:nil];
    [accountsManager account:account didBecomeInvalidFromHTTPError:error];
    // Then: manager deactivated the account and is signed out.
    [self assertAccountsManagerDeactivatedAccountAndIsSignedOut];
    // Then: delegate method is called with account.
    OCMVerify([self.delegateMock accountsManager:self.accountsManager didSignOutOfInvalidAccount:account fromHTTPError:error]);
}

- (void)testAccountPersistence
{
    // Given: delegate allows account persistence.
    self.delegateMock = OCMProtocolMock(@protocol(NBAccountsManagerDelegate));
    [OCMStub([self.delegateMock accountsManagerShouldPersistAccounts:OCMOCK_ANY]) andReturnValue:@YES];
    NBAccountsManager *accountsManager = self.accountsManagerMock;
    // Given: manager has populated accounts.
    [self populateAccountsManagerWithAccountMocks:accountsManager];
    // Given: accounts manager can properly create accounts.
    [OCMStub([accountsManager createAccountWithNationSlug:self.nationSlug]) andReturn:[self createAccountMock]];
    // When: persisting and removing accounts, then loading accounts.
    NSUInteger originalCount = accountsManager.accounts.count;
    [self performAccountPersistenceWithAccountsManager:accountsManager];
    // Then: accounts should be restored and manager should be signed in.
    XCTAssertTrue(accountsManager.isSignedIn,
                  @"Manager should be signed in.");
    XCTAssertNotNil(accountsManager.selectedAccount,
                    @"Manager should have a selected account.");
    XCTAssertEqual(accountsManager.accounts.count, originalCount,
                      @"Manager should have same number of accounts as before.");
}

- (void)testAccountPersistenceDisabling
{
    NBAccountsManager *accountsManager = self.accountsManagerMock;
    // Given: manager has populated accounts.
    [self populateAccountsManagerWithAccountMocks:accountsManager];
    // Given: accounts manager can properly create accounts.
    [OCMStub([accountsManager createAccountWithNationSlug:self.nationSlug]) andReturn:[self createAccountMock]];
    // When: persisting and removing accounts, then loading accounts.
    [self performAccountPersistenceWithAccountsManager:accountsManager];
    // Then: accounts should be empty and manager should not be signed in.
    XCTAssertFalse(accountsManager.isSignedIn,
                   @"Manager should not be signed in.");
    XCTAssertNil(accountsManager.selectedAccount,
                 @"Manager should not have a selected account.");
    XCTAssertEqual(accountsManager.accounts.count, 0,
                   @"Manager should have no accounts.");
}

@end
