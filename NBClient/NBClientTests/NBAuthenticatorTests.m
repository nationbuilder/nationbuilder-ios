//
//  NBAuthenticatorTests.m
//  NBClient
//
//  Created by Peng Wang on 7/10/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBTestCase.h"

#import "NBAuthenticator.h"

@interface NBAuthenticatorTests : NBTestCase

@property (nonatomic, strong) NSString *credentialIdentifier;

@end

@implementation NBAuthenticatorTests

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

@end
