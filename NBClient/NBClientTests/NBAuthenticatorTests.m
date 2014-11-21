//
//  NBAuthenticatorTests.m
//  NBClient
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBTestCase.h"

#import <UIKit/UIKit.h>

#import "FoundationAdditions.h"

#import "NBAuthenticator.h"
#import "NBAuthenticator_Internal.h"

@interface NBAuthenticatorTests : NBTestCase

@property (nonatomic, copy) NSString *credentialIdentifier;

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
    self.credentialIdentifier = @"authenticator-tests.nationbuilder.com";
}

- (void)tearDown
{
    [super tearDown];
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

- (void)testManagingCredentialInKeychain
{
    NSString *accessToken = @"abc123";
    NBAuthenticationCredential *credential = [[NBAuthenticationCredential alloc]
                                              initWithAccessToken:accessToken tokenType:@"bearer"];
    XCTAssertTrue([NBAuthenticationCredential saveCredential:credential withIdentifier:self.credentialIdentifier],
                  @"Authentication credential should be successfully saved to keychain.");
    credential = [NBAuthenticationCredential fetchCredentialWithIdentifier:self.credentialIdentifier];
    XCTAssertNotNil(credential,
                    @"Authentication credential should be successfully fetched from keychain.");
    XCTAssertTrue([credential.accessToken isEqualToString:accessToken],
                   @"Authentication credential should be valid.");
    XCTAssertTrue([NBAuthenticationCredential deleteCredentialWithIdentifier:self.credentialIdentifier],
                  @"Authentication credential should be successfully deleted from keychain.");
    XCTAssertNil([NBAuthenticationCredential fetchCredentialWithIdentifier:self.credentialIdentifier],
                 @"Authentication credential should be not be in keychain.");
}

- (void)testAuthenticateWithRedirectPath
{
    // Given: specified redirect scheme, URI, and resulting access token.
    NSString *urlScheme = @"sample-app.nationbuilder";
    NSString *redirectPath = NBAuthenticationDefaultRedirectPath;
    NSString *accessToken = @"somehash";
    NSURL *redirectURI = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", urlScheme, redirectPath]];
    // Given: an application that can open authorization URL (Safari).
    id applicationMock = OCMClassMock([UIApplication class]);
    [OCMStub([applicationMock sharedApplication]) andReturn:applicationMock];
    [OCMStub([applicationMock canOpenURL:OCMOCK_ANY]) andReturnValue:@YES];
    // Given: an authenticator that doesn't affect global state.
    id authenticatorMock = OCMPartialMock([[NBAuthenticator alloc] initWithBaseURL:self.baseURL
                                                                  clientIdentifier:self.clientIdentifier]);
    [authenticatorMock setShouldPersistCredential:NO];
    // Given: a properly registered application url scheme.
    [OCMStub([authenticatorMock authorizationRedirectApplicationURLScheme]) andReturn:urlScheme];
    // Given: user authorization and subsequent opening of redirect URI in app.
    [OCMStub([applicationMock openURL:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        // Then: verify authorization url.
        NSURL *authorizationURL;
        [invocation getArgument:&authorizationURL atIndex:2];
        [invocation retainArguments];
        NSDictionary *expectedParameters = @{ @"client_id": self.clientIdentifier, @"response_type": @"token", @"redirect_uri": redirectURI.absoluteString };
        NSURLComponents *components = [[NSURLComponents alloc]initWithURL:authorizationURL resolvingAgainstBaseURL:YES];
        XCTAssertTrue([components.path isEqualToString:@"/oauth/authorize"],
                      @"Authorization url path should be correct.");
        XCTAssertTrue([components.host isEqualToString:self.baseURL.host],
                      @"Authorization url host should be correct.");
        XCTAssertTrue([[components.query nb_queryStringParametersWithEncoding:NSASCIIStringEncoding] nb_containsDictionary:expectedParameters],
                      @"Authorization url parameters should be correct.");
        // App delegate method would call this.
        [NBAuthenticator finishAuthenticatingInWebBrowserWithURL:
         [NSURL URLWithString:[NSString stringWithFormat:@"#access_token=%@", accessToken] relativeToURL:redirectURI] error:nil];
    }];
    [self setUpAsync];
    // When.
    [authenticatorMock authenticateWithRedirectPath:redirectPath priorSignout:NO completionHandler:^(NBAuthenticationCredential *credential, NSError *error) {
        // Then: verify credential.
        XCTAssertTrue([credential.accessToken isEqualToString:accessToken],
                      @"Should return credential with correct access token.");
        [self completeAsync];
    }];
    [self tearDownAsync];
}

// NOTE: Credential persistence is tested in NBClientTests.

@end
