//
//  NBClientTests.m
//  NBClientTests
//
//  Created by Peng Wang on 7/8/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBTestCase.h"

#import "Main.h"

@interface NBClientTests : NBTestCase @end

@implementation NBClientTests

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
    NBClient *client = [[NBClient alloc] initWithNationName:self.nationName
                                                     apiKey:self.apiKey
                                              customBaseURL:self.baseURL
                                           customURLSession:nil customURLSessionConfiguration:nil];
    XCTAssertNotNil(client.urlSession,
                    @"Client should have default session.");
    XCTAssertNotNil(client.sessionConfiguration,
                    @"Client should have default session configuration.");
    XCTAssertNotNil(client.sessionConfiguration.URLCache,
                    @"Client should have default session cache.");
}

- (void)testAsyncAuthenticatedInitialization
{
    [self setUpAsync];
    NBAuthenticator *authenticator = [[NBAuthenticator alloc] initWithBaseURL:self.baseURL
                                                             clientIdentifier:self.clientIdentifier
                                                                 clientSecret:self.clientSecret];
    NBClient *client = [[NBClient alloc] initWithNationName:self.nationName
                                              authenticator:authenticator
                                           customURLSession:nil customURLSessionConfiguration:nil];
    XCTAssertEqual(client.authenticator, authenticator,
                   @"Client should have authenticator.");
    NSURLSessionDataTask *task =
    [client.authenticator
     authenticateWithUserName:self.userEmailAddress
     password:self.userPassword
     completionHandler:^(NBAuthenticationCredential *credential, NSError *error) {
         if (error) {
             XCTFail(@"Authentication service returned error %@", error);
         }
         NSLog(@"CREDENTIAL: %@", credential);
         XCTAssertNotNil(credential.accessToken,
                         @"Credential should have access token.");
         XCTAssertNotNil(credential.tokenType,
                         @"Credential should have token type.");
         client.apiKey = credential.accessToken;
         [self completeAsync];
    }];
    XCTAssertTrue(task && task.state == NSURLSessionTaskStateRunning,
                  @"Authenticator should have created and ran task.");
    NSLog(@"REQUEST: %@", task.currentRequest.nb_debugDescription);
    [self tearDownAsync];
}

@end
