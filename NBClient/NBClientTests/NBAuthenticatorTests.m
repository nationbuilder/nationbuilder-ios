//
//  NBAuthenticatorTests.m
//  NBClient
//
//  Created by Peng Wang on 7/10/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBTestCase.h"

#import "NBAuthenticator.h"

@interface NBAuthenticatorTests : NBTestCase @end

@implementation NBAuthenticatorTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testDefaultInitialization
{
    NBAuthenticator *authenticator = [[NBAuthenticator alloc] initWithBaseURL:self.baseURL
                                                             clientIdentifier:self.clientIdentifier
                                                                 clientSecret:self.clientSecret];
    XCTAssertNotNil(authenticator.baseURL,
                    @"Authenticator should have base URL.");
    XCTAssertNotNil(authenticator.clientIdentifier,
                    @"Authenticator should have client ID.");
}

@end
