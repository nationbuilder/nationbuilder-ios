//
//  NBAuthenticatorTests.m
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBTestCase.h"

#import <UIKit/UIKit.h>

#import "FoundationAdditions.h"

#import "NBAuthenticator.h"
#import "NBAuthenticator_Internal.h"

@interface NBAuthenticatorTests : NBTestCase

@property (nonatomic, copy) NSString *credentialIdentifier;
@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *redirectPath;
@property (nonatomic, copy) NSString *redirectURLScheme;

@property (nonatomic, copy, readonly) NSURL *redirectURI;

@end

@implementation NBAuthenticatorTests

+ (void)setUp
{
    [super setUp];
    [NBAuthenticator updateLoggingToLevel:NBLogLevelWarning];
}

- (void)setUp
{
    [super setUp];
    self.accessToken = @"somehash";
    self.credentialIdentifier = @"authenticator-tests.nationbuilder.com";
    self.redirectPath = NBAuthenticationDefaultRedirectPath;
    self.redirectURLScheme = @"sample-app.nationbuilder";
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - Helpers

- (NSURL *)redirectURI
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", self.redirectURLScheme, self.redirectPath]];
}

#pragma mark - Tests

- (void)testDefaultInitialization
{
    NBAuthenticator *authenticator = [[NBAuthenticator alloc] initWithBaseURL:self.baseURL
                                                             clientIdentifier:self.clientIdentifier];
    XCTAssertNotNil(authenticator.baseURL,
                    @"Authenticator should have base URL.");
    XCTAssertNotNil(authenticator.clientIdentifier,
                    @"Authenticator should have client ID.");
    XCTAssertNotNil(authenticator.credentialIdentifier,
                    @"Authenticator should have credential ID.");
}

- (void)x_testManagingCredentialInKeychain
{
    NBAuthenticationCredential *credential = [[NBAuthenticationCredential alloc]
                                              initWithAccessToken:self.accessToken tokenType:@"bearer"];
    XCTAssertTrue([NBAuthenticationCredential saveCredential:credential withIdentifier:self.credentialIdentifier],
                  @"Authentication credential should be successfully saved to keychain.");
    credential = [NBAuthenticationCredential fetchCredentialWithIdentifier:self.credentialIdentifier];
    XCTAssertNotNil(credential,
                    @"Authentication credential should be successfully fetched from keychain.");
    XCTAssertTrue([credential.accessToken isEqualToString:self.accessToken],
                   @"Authentication credential should be valid.");
    XCTAssertTrue([NBAuthenticationCredential deleteCredentialWithIdentifier:self.credentialIdentifier],
                  @"Authentication credential should be successfully deleted from keychain.");
    XCTAssertNil([NBAuthenticationCredential fetchCredentialWithIdentifier:self.credentialIdentifier],
                 @"Authentication credential should be not be in keychain.");
}

- (void)testSetCredentialWithAccessToken
{
    NBAuthenticator *authenticator = [[NBAuthenticator alloc] initWithBaseURL:self.baseURL
                                                             clientIdentifier:self.clientIdentifier];
    [authenticator setCredentialWithAccessToken:self.accessToken tokenType:nil];
    XCTAssertTrue([authenticator.credential.accessToken isEqualToString:self.accessToken],
                  @"Credential should be set.");
}

- (void)testAuthenticationURLWithRedirectPath
{
    // Given: a properly registered application url scheme.
    id classMock = OCMClassMock([NBAuthenticator class]);
    [OCMStub([classMock authorizationRedirectApplicationURLScheme]) andReturn:self.redirectURLScheme];
    // Then: verify url.
    NBAuthenticator *authenticator = [[NBAuthenticator alloc] initWithBaseURL:self.baseURL
                                                             clientIdentifier:self.clientIdentifier];
    NSURL *url = [authenticator authenticationURLWithRedirectPath:self.redirectPath];
    NSString *redirectURIQueryString = [self.redirectURI.absoluteString
                                        nb_percentEscapedQueryStringWithEncoding:NSUTF8StringEncoding
                                        charactersToLeaveUnescaped:nil];
    NSURL *expectedURL = [NSURL URLWithString:[NSString stringWithFormat:
                                               @"/oauth/authorize?client_id=%@&redirect_uri=%@&response_type=token",
                                               self.clientIdentifier, redirectURIQueryString]
                                relativeToURL:self.baseURL];
    XCTAssertTrue([url.absoluteString isEqualToString:expectedURL.absoluteString],
                  @"Returns expected url.");
}

// TODO: Blinker.
- (void)x_testAuthenticateWithRedirectPath
{
    // Given: an authenticator that doesn't affect global state.
    id authenticatorMock = OCMPartialMock([[NBAuthenticator alloc] initWithBaseURL:self.baseURL
                                                                  clientIdentifier:self.clientIdentifier]);
    [authenticatorMock setShouldPersistCredential:NO];
    // Given: a properly registered application url scheme.
    [OCMStub([authenticatorMock authorizationRedirectApplicationURLScheme]) andReturn:self.redirectURLScheme];
    // Given: user authorization and subsequent opening of redirect URI in app.
    [OCMStub([authenticatorMock openURLWithWebBrowser:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        // Then: verify authorization url.
        NSURL *authorizationURL;
        [invocation getArgument:&authorizationURL atIndex:2];
        [invocation retainArguments];
        NSDictionary *expectedParameters = @{ @"client_id": self.clientIdentifier, @"response_type": @"token", @"redirect_uri": self.redirectURI.absoluteString };
        NSURLComponents *components = [[NSURLComponents alloc]initWithURL:authorizationURL resolvingAgainstBaseURL:YES];
        XCTAssertTrue([components.path isEqualToString:@"/oauth/authorize"],
                      @"Authorization url path should be correct.");
        XCTAssertTrue([components.host isEqualToString:self.baseURL.host],
                      @"Authorization url host should be correct.");
        XCTAssertTrue([components.percentEncodedQuery.nb_queryStringParameters nb_containsDictionary:expectedParameters],
                      @"Authorization url parameters should be correct.");
        // App delegate method would call this.
        [NBAuthenticator finishAuthenticatingInWebBrowserWithURL:
         [NSURL URLWithString:[NSString stringWithFormat:@"#access_token=%@", self.accessToken] relativeToURL:self.redirectURI]];
    }];
    [self setUpAsync];
    // When.
    [authenticatorMock authenticateWithRedirectPath:self.redirectPath priorSignout:NO completionHandler:^(NBAuthenticationCredential *credential, NSError *error) {
        // Then: verify credential.
        XCTAssertTrue([credential.accessToken isEqualToString:self.accessToken],
                      @"Should return credential with correct access token.");
        [self completeAsync];
    }];
    [self tearDownAsync];
}

// NOTE: Credential persistence is tested in NBClientTests.

@end
