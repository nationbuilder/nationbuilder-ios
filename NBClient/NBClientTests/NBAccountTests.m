//
//  NBAccountTests.m
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import "NBTestCase.h"

#import "FoundationAdditions.h"

#import "NBAccount.h"
#import "NBAccount_Internal.h"
#import "NBAuthenticator.h"
#import "NBAuthenticator_Internal.h"
#import "NBClient+People.h"

@interface NBAccountTests : NBTestCase

@property (nonatomic) NBAccount *account;
@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic) id delegateMock;

@end

@implementation NBAccountTests

- (void)setUp
{
    [super setUp];
    // Setup main test account.
    self.accessToken = @"somehash";
    self.delegateMock = OCMProtocolMock(@protocol(NBAccountDelegate));
    [self stubInfoFileBundleResourcePathForOperations:^{
        self.account = [[NBAccount alloc] initWithClientInfo:nil delegate:self.delegateMock];
    }];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - Helpers

- (void)stubPersonDataForClient:(NBClient *)client
{
    [self stubRequestUsingFileDataWithMethod:@"GET" pathFormat:@"people/me" pathVariables:nil
                             queryParameters:@{ @"access_token": self.accessToken } variant:nil
                                      client:client];
}

#pragma mark - Tests

- (void)testDefaultInitialization
{
    XCTAssertNotNil(self.account.clientInfo, @"Account always requires client info.");
    XCTAssertTrue([self.account.clientInfo nb_containsDictionary:self.account.defaultClientInfo],
                  @"Account should fallback to using default client info.");
    XCTAssertNotNil(self.account.client, @"Client should be ready.");
    XCTAssertNotNil(self.account.authenticator, @"Authenticator should be ready.");
}

- (void)testInitializationWithTestToken
{
    self.account.shouldUseTestToken = YES;
    NBClient *client = self.account.client;
    XCTAssertEqual(client.apiKey, self.account.clientInfo[NBInfoTestTokenKey],
                   @"Client should be using the test token.");
    XCTAssertNil(client.authenticator, @"Authenticator should be unset.");
}

- (void)testCredentialIdentifierUpdating
{
    NBAuthenticator *authenticator = self.account.authenticator;
    NSString *originalCredentialIdentifier = authenticator.credentialIdentifier;
    // Given: new identifying property values.
    NSString *name = @"Foo Bar";
    NSUInteger identifier = 123;
    // When: updating these properties.
    self.account.name = name;
    self.account.identifier = identifier;
    // Then: credential identifier gets updated as well.
    XCTAssertFalse([authenticator.credentialIdentifier isEqualToString:originalCredentialIdentifier],
                   @"Credential identifier should be updated.");
    XCTAssertTrue(([authenticator.credentialIdentifier rangeOfString:name].location != NSNotFound &&
                   [authenticator.credentialIdentifier rangeOfString:[NSString stringWithFormat:@"%lu", (unsigned long)identifier]].location != NSNotFound),
                  @"Credential identifier should contain new account name and identifier.");
}

- (void)testActivationAndPersonFetching
{
    [self setUpAsyncWithHTTPStubbing:YES];
    id accountMock = OCMPartialMock(self.account);
    [accountMock setShouldAutoFetchAvatar:NO];
    if (self.shouldUseHTTPStubbing) {
        [self stubPersonDataForClient:[(NBAccount *)accountMock client]];
    }
    // Given: an authenticator that authenticates properly using the token flow.
    id authenticatorMock = OCMPartialMock(self.account.authenticator);
    [OCMStub([accountMock authenticator]) andReturn:authenticatorMock];
    [OCMStub([authenticatorMock authenticateWithRedirectPath:OCMOCK_ANY priorSignout:NO completionHandler:OCMOCK_ANY])
     andDo:^(NSInvocation *invocation) {
         NBAuthenticationCompletionHandler completionHandler;
         [invocation getArgument:&completionHandler atIndex:4];
         [invocation retainArguments];
         NBAuthenticationCredential *credential = [[NBAuthenticationCredential alloc] initWithAccessToken:self.accessToken tokenType:nil];
         completionHandler(credential, nil);
     }];
    // Given: keychain persistence that works.
    id credentialMock = OCMClassMock([NBAuthenticationCredential class]);
    [OCMStub([credentialMock saveCredential:OCMOCK_ANY withIdentifier:OCMOCK_ANY]) andReturnValue:@YES];
    // Given.
    XCTAssertNil(self.account.person, @"Initial account should have no person data.");
    // When.
    [accountMock requestActiveWithPriorSignout:NO completionHandler:^(NSError *error) {
        if (error) {
            XCTFail(@"Request to make account active failed with error %@", error);
        }
        NBAccount *account = accountMock;
        // Then: data should be present.
        XCTAssertNotNil(account.person, @"Account should have person data.");
        XCTAssertTrue([account.client.apiKey isEqualToString:self.accessToken],
                      @"Account client should be authenticated.");
        XCTAssertTrue(([[authenticatorMock credentialIdentifier] rangeOfString:account.name].location != NSNotFound &&
                       [[authenticatorMock credentialIdentifier] rangeOfString:[NSString stringWithFormat:@"%lu", (unsigned long)account.identifier]].location != NSNotFound),
                      @"Credential identifier should contain new account name and identifier.");
        [self completeAsync];
    }];
    [self tearDownAsync];
}

- (void)testActivationFromSavedCredential
{
    [self setUpAsyncWithHTTPStubbing:YES];
    id accountMock = OCMPartialMock(self.account);
    [accountMock setShouldAutoFetchAvatar:NO];
    if (self.shouldUseHTTPStubbing) {
        [self stubPersonDataForClient:[(NBAccount *)accountMock client]];
    }
    // Given: an authenticator with a stored credential.
    id authenticatorMock = OCMPartialMock(self.account.authenticator);
    [OCMStub([accountMock authenticator]) andReturn:authenticatorMock];
    [authenticatorMock setCredential:[[NBAuthenticationCredential alloc] initWithAccessToken:self.accessToken tokenType:nil]];
    // Then: authentication should be skipped.
    [OCMStub([authenticatorMock authenticateWithRedirectPath:OCMOCK_ANY priorSignout:NO completionHandler:OCMOCK_ANY])
     andDo:^(NSInvocation *invocation) {
         XCTFail(@"Default authentication request should not occur.");
     }];
    // When.
    [accountMock requestActiveWithPriorSignout:NO completionHandler:^(NSError *error) {
        [self completeAsync];
    }];
    [self tearDownAsync];
}

- (void)testDeactivationAndCleanup
{
    // Given: account has authenticator with credential and working client.
    self.account.authenticator.credential = [[NBAuthenticationCredential alloc] initWithAccessToken:self.accessToken tokenType:nil];
    self.account.client.apiKey = self.account.authenticator.credential.accessToken;
    // Given: keychain persistence that works.
    id credentialMock = OCMClassMock([NBAuthenticationCredential class]);
    [OCMStub([credentialMock deleteCredentialWithIdentifier:OCMOCK_ANY]) andReturnValue:@YES];
    // When.
    [self.account requestCleanUpWithError:nil];
    // Then.
    XCTAssertNil(self.account.authenticator.credential, @"Account's authenticator should no longer have the credential.");
    XCTAssertNil(self.account.client.apiKey, @"Account's client should no longer have an API key.");
}

- (void)testDelegateDidBecomeInvalidFromHTTPError
{
    [self setUpAsyncWithHTTPStubbing:YES];
    // Given: account delegate properly implements method.
    [OCMStub([self.delegateMock account:OCMOCK_ANY didBecomeInvalidFromHTTPError:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        [self completeAsync];
    }];
    // Given: account properly cleans up.
    self.account.authenticator = OCMPartialMock(self.account.authenticator);
    [OCMStub([self.account.authenticator discardCredential]) andReturnValue:@YES];
    // Given: account client properly returns 401 if access token is invalid or has expired.
    self.account.shouldUseTestToken = YES;
    [self stubRequestWithMethod:@"GET" pathFormat:@"people/me" pathVariables:nil queryParameters:nil client:self.account.client].andReturn(401);
    // When making a request that returns 401, then the delegate method should be called.
    [self.account.client fetchPersonForClientUserWithCompletionHandler:^(NSDictionary *item, NSError *error) {
        XCTFail(@"Default response handling should not occur.");
    }];
    [self tearDownAsync];
}

@end
