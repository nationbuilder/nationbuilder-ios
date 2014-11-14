//
//  NBAccountTests.m
//  NBClient
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
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
@property (nonatomic) id delegateMock;

@end

@implementation NBAccountTests

- (void)setUp
{
    [super setUp];
    // Setup main test account.
    self.delegateMock = OCMProtocolMock(@protocol(NBAccountDelegate));
    [self stubInfoFileBundleResourcePathForOperations:^{
        self.account = [[NBAccount alloc] initWithClientInfo:nil delegate:self.delegateMock];
    }];
}

- (void)tearDown
{
    [super tearDown];
}

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
    // Given: an authenticator that authenticates properly using the token flow.
    id accountMock = OCMPartialMock(self.account);
    id authenticatorMock = OCMPartialMock(self.account.authenticator);
    [OCMStub([accountMock authenticator]) andReturn:authenticatorMock];
    NSString *accessToken = @"somehash";
    [OCMStub([authenticatorMock authenticateWithRedirectPath:OCMOCK_ANY priorSignout:NO completionHandler:OCMOCK_ANY])
     andDo:^(NSInvocation *invocation) {
         NBAuthenticationCompletionHandler completionHandler;
         [invocation getArgument:&completionHandler atIndex:4];
         [invocation retainArguments];
         NBAuthenticationCredential *credential = [[NBAuthenticationCredential alloc] initWithAccessToken:accessToken tokenType:nil];
         completionHandler(credential, nil);
     }];
    // Given: a client that properly fetches person data for its account user.
    [self stubRequestUsingFileDataWithMethod:@"GET" path:@"people/me" identifier:NSNotFound parameters:@{ @"access_token": accessToken }
                                      client:(id)[accountMock client]];
    // Given: keychain persistence that works.
    id credentialMock = OCMClassMock([NBAuthenticationCredential class]);
    [OCMStub([credentialMock saveCredential:OCMOCK_ANY withIdentifier:OCMOCK_ANY]) andReturnValue:@YES];
    // Given: person data with a valid avatar image URL.
    stubRequest(@"GET", @"https://d3n8a8pro7vhmx.cloudfront.net/assets/icons/buddy.png");
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
        XCTAssertNotNil(account.avatarImageData, @"Account should have avatar image.");
        XCTAssertTrue([account.client.apiKey isEqualToString:accessToken],
                      @"Account client should be authenticated.");
        XCTAssertTrue(([[authenticatorMock credentialIdentifier] rangeOfString:account.name].location != NSNotFound &&
                       [[authenticatorMock credentialIdentifier] rangeOfString:[NSString stringWithFormat:@"%lu", (unsigned long)account.identifier]].location != NSNotFound),
                      @"Credential identifier should contain new account name and identifier.");
        [self completeAsync];
    }];
    [self tearDownAsync];
}

- (void)testDeactivationAndCleanup
{
    // Given: account has authenticator with credential and working client.
    self.account.authenticator.credential = [[NBAuthenticationCredential alloc] initWithAccessToken:@"somehash" tokenType:nil];
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
    [self stubRequestWithMethod:@"GET" path:@"people/me" identifier:NSNotFound parameters:nil client:self.account.client].andReturn(401);
    // When making a request that returns 401, then the delegate method should be called.
    [self.account.client fetchPersonForClientUserWithCompletionHandler:^(NSDictionary *item, NSError *error) {
        XCTFail(@"Default response handling should not occur.");
    }];
    [self tearDownAsync];
}

@end
