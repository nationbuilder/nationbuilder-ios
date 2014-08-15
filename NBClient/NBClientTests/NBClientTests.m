//
//  NBClientTests.m
//  NBClientTests
//
//  Created by Peng Wang on 7/8/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBTestCase.h"

#import "Main.h"

@interface NBClientTests : NBTestCase

@property (nonatomic, weak, readonly) NBClient *baseClientWithAuthenticator;
@property (nonatomic, weak, readonly) NBClient *baseClientWithTestToken;

- (void)assertCredential:(NBAuthenticationCredential *)credential;

@end

@implementation NBClientTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - Helpers

- (NBClient *)baseClientWithAuthenticator
{
    NBAuthenticator *authenticator = [[NBAuthenticator alloc] initWithBaseURL:self.baseURL
                                                             clientIdentifier:self.clientIdentifier
                                                                 clientSecret:self.clientSecret];
    return [[NBClient alloc] initWithNationName:self.nationName
                                  authenticator:authenticator
                               customURLSession:nil customURLSessionConfiguration:nil];
}
- (NBClient *)baseClientWithTestToken
{
    return [[NBClient alloc] initWithNationName:self.nationName
                                         apiKey:self.testToken
                                  customBaseURL:self.baseURL
                               customURLSession:nil customURLSessionConfiguration:nil];
}

- (void)assertCredential:(NBAuthenticationCredential *)credential
{
    XCTAssertNotNil(credential.accessToken,
                    @"Credential should have access token.");
    XCTAssertNotNil(credential.tokenType,
                    @"Credential should have token type.");
}

#pragma mark - Tests

- (void)testDefaultInitialization
{
    NBClient *client = self.baseClientWithTestToken;
    XCTAssertNotNil(client.urlSession,
                    @"Client should have default session.");
    XCTAssertNotNil(client.sessionConfiguration,
                    @"Client should have default session configuration.");
    XCTAssertNotNil(client.sessionConfiguration.URLCache,
                    @"Client should have default session cache.");
}

- (void)testAsyncAuthenticatedInitialization
{
    if (self.shouldOnlyUseTestToken) {
        NSLog(@"SKIPPING");
        return;
    }
    [self setUpAsync];
    NBClient *client = self.baseClientWithAuthenticator;
    XCTAssertNotNil(client.authenticator,
                    @"Client should have authenticator.");
    NSString *credentialIdentifier = client.authenticator.credentialIdentifier;
    [NBAuthenticationCredential deleteCredentialWithIdentifier:credentialIdentifier];
    NSURLSessionDataTask *task =
    [client.authenticator
     authenticateWithUserName:self.userEmailAddress
     password:self.userPassword
     completionHandler:^(NBAuthenticationCredential *credential, NSError *error) {
         if (error) {
             XCTFail(@"Authentication service returned error %@", error);
         }
         NSLog(@"CREDENTIAL: %@", credential);
         [self assertCredential:credential];
         client.apiKey = credential.accessToken;
         // Test credential persistence across initializations.
         XCTAssertTrue(client.authenticator.shouldAutomaticallySaveCredential,
                       @"Authenticator should have automatically saved credential to keychain.");
         NBClient *client = self.baseClientWithAuthenticator;
         NSURLSessionDataTask *task =
         [client.authenticator
          authenticateWithUserName:self.userEmailAddress
          password:self.userPassword
          completionHandler:^(NBAuthenticationCredential *credential, NSError *error) {
              if (error) {
                  XCTFail(@"Authentication service returned error %@", error);
              }
              [self assertCredential:credential];
          }];
         XCTAssertNil(task,
                      @"Saved credential should have been fetched to obviate authenticating against service.");
         [self completeAsync];
     }];
    XCTAssertTrue(task && task.state == NSURLSessionTaskStateRunning,
                  @"Authenticator should have created and ran task.");
    [self tearDownAsync];
}

- (void)testConfiguringAPIVersion
{
    if (self.shouldUseHTTPStubbing) {
        NSLog(@"SKIPPING");
        return;
    }
    NBClient *client = self.baseClientWithTestToken;
    client.apiVersion = [NBClientDefaultAPIVersion stringByAppendingString:@"0"];
    NSURLSessionDataTask *task = [client fetchPeopleWithPaginationInfo:nil completionHandler:nil];
    [task cancel];
    NSString *path = [[NSURLComponents componentsWithURL:task.currentRequest.URL resolvingAgainstBaseURL:YES] path];
    XCTAssertTrue([path rangeOfString:client.apiVersion].location != NSNotFound,
                  @"Version string in all future request URLs should have been updated.");
}

@end
