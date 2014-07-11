//
//  NBAuthenticatorTests.m
//  NBClient
//
//  Created by Peng Wang on 7/10/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NBAuthenticator.h"

@interface NBAuthenticatorTests : XCTestCase

@property (strong, nonatomic) NSURL *baseURL;
@property (strong, nonatomic) NSString *clientIdentifier;
@property (strong, nonatomic) NSString *clientSecret;

@end

@implementation NBAuthenticatorTests

- (void)setUp
{
    [super setUp];
    self.baseURL = [NSURL URLWithString:@"http://abeforprez.nbuild.dev"];
    self.clientIdentifier = @"ca76d8aa658b4a0af4aba5599f4443bed47895025799a63f9f75669ebc67dd9d";
    self.clientSecret = @"6c63db2494d69f715157075d1794074a522990a97dc1324910d605c89859b4a8";
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
