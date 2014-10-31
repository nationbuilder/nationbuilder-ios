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

@property (nonatomic, weak, readonly) NBClient *baseClientWithTestTokenAndMockDelegate;
@property (nonatomic, weak, readonly) NBClientResourceItemCompletionHandler delegateShouldHandleResponseForRequestFailBlock;
@property (nonatomic, weak, readonly) void (^delegateShouldHandleResponseForRequestPassBlock)(NSInvocation *);

- (LSStubRequestDSL *)stubSomeRequestWithClient:(NBClient *)client;

@end

@implementation NBClientTests

+ (void)setUp
{
    [super setUp];
    [[LSNocilla sharedInstance] start];
}

+ (void)tearDown
{
    [super tearDown];
    [[LSNocilla sharedInstance] stop];
}

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - Initialization

#pragma mark Helpers

- (NBClient *)baseClientWithAuthenticator
{
    NBAuthenticator *authenticator = [[NBAuthenticator alloc] initWithBaseURL:self.baseURL
                                                             clientIdentifier:self.clientIdentifier];
    return [[NBClient alloc] initWithNationName:self.nationName
                                  authenticator:authenticator
                               customURLSession:[NSURLSession sharedSession]
                  customURLSessionConfiguration:nil];
}
- (NBClient *)baseClientWithTestToken
{
    return [[NBClient alloc] initWithNationName:self.nationName
                                         apiKey:self.testToken
                                  customBaseURL:self.baseURL
                               customURLSession:[NSURLSession sharedSession]
                  customURLSessionConfiguration:nil];
}

- (void)assertCredential:(NBAuthenticationCredential *)credential
{
    XCTAssertNotNil(credential.accessToken,
                    @"Credential should have access token.");
    XCTAssertNotNil(credential.tokenType,
                    @"Credential should have token type.");
}

#pragma mark Tests

- (void)testDefaultInitialization
{
    NBClient *client = [self baseClientWithTestToken];
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
        NBLog(@"SKIPPING");
        return;
    }
    [self setUpAsync];
    NBClient *client = [self baseClientWithAuthenticator];
    XCTAssertNotNil(client.authenticator,
                    @"Client should have authenticator.");
    NSString *credentialIdentifier = client.authenticator.credentialIdentifier;
    [NBAuthenticationCredential deleteCredentialWithIdentifier:credentialIdentifier];
    NSURLSessionDataTask *task =
    [client.authenticator
     authenticateWithUserName:self.userEmailAddress
     password:self.userPassword
     clientSecret:self.clientSecret
     completionHandler:^(NBAuthenticationCredential *credential, NSError *error) {
         if (error) {
             XCTFail(@"Authentication service returned error %@", error);
         }
         NBLog(@"CREDENTIAL: %@", credential);
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
          clientSecret:self.clientSecret
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
        NBLog(@"SKIPPING");
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

#pragma mark - Delegation

#pragma mark Helpers

- (NBClient *)baseClientWithTestTokenAndMockDelegate
{
    NBClient *client = [self baseClientWithTestToken];
    client.delegate = OCMProtocolMock(@protocol(NBClientDelegate));
    [OCMStub([client.delegate client:client shouldAutomaticallyStartDataTask:OCMOCK_ANY]) andReturnValue:@YES];
    return client;
}

- (NBClientResourceItemCompletionHandler)delegateShouldHandleResponseForRequestFailBlock
{
    return ^(NSDictionary *item, NSError *error) {
        XCTFail(@"Default response handling should not occur.");
        [self completeAsync];
    };
}

- (void (^)(NSInvocation *))delegateShouldHandleResponseForRequestPassBlock
{
    return ^(NSInvocation *invocation) {
        BOOL shouldHandleResponse = NO;
        [invocation setReturnValue:&shouldHandleResponse];
        [self completeAsync]; // NOTE: This is a bit fudgy.
    };
}

- (LSStubRequestDSL *)stubSomeRequestWithClient:(NBClient *)client
{
    return [self stubRequestWithMethod:@"GET" path:@"people/me" identifier:NSNotFound parameters:nil client:client];
}

#pragma mark Tests

- (void)testDelegateShouldHandleResponseForRequest
{
    [self setUpAsync];
    NBClient *client = [self baseClientWithTestTokenAndMockDelegate];
    // Mock delegate and stub method.
    OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY])
    .andDo([self delegateShouldHandleResponseForRequestPassBlock]);
    // Stub and make request.
    [self stubSomeRequestWithClient:client].andReturn(200);
    [client fetchPersonForClientUserWithCompletionHandler:[self delegateShouldHandleResponseForRequestFailBlock]];
    [self tearDownAsync];
}

// OCMProtocolMock allows the object to respond to all protocol method selectors,
// even the optional ones. This means there is additional boilerplate to explicitly
// stub as many methods as needed to reach the one we're testing.

- (void)testDelegateShouldHandleResponseForRequestWithDataTaskError
{
    [self setUpAsync];
    NBClient *client = [self baseClientWithTestTokenAndMockDelegate];
    // Mock delegate and stub method.
    [OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY]) andReturnValue:@YES];
    OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY withDataTaskError:OCMOCK_ANY])
    .andDo([self delegateShouldHandleResponseForRequestPassBlock]);
    // Stub and make request.
    [self stubSomeRequestWithClient:client].andFailWithError([NSError errorWithDomain:NBErrorDomain code:0 userInfo:nil]);
    [client fetchPersonForClientUserWithCompletionHandler:[self delegateShouldHandleResponseForRequestFailBlock]];
    [self tearDownAsync];
}

- (void)testDelegateShouldHandleResponseForRequestWithHTTPError
{
    [self setUpAsync];
    NBClient *client = [self baseClientWithTestTokenAndMockDelegate];
    // Mock delegate and stub method.
    [OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY]) andReturnValue:@YES];
    [OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY withDataTaskError:OCMOCK_ANY]) andReturnValue:@YES];
    OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY withHTTPError:OCMOCK_ANY])
    .andDo([self delegateShouldHandleResponseForRequestPassBlock]);
    // Stub and make request.
    [self stubSomeRequestWithClient:client].andReturn(404);
    [client fetchPersonForClientUserWithCompletionHandler:[self delegateShouldHandleResponseForRequestFailBlock]];
    [self tearDownAsync];
}

- (void)testDelegateShouldHandleResponseForRequestWithServiceError
{
    [self setUpAsync];
    NBClient *client = [self baseClientWithTestTokenAndMockDelegate];
    // Mock delegate and stub method.
    [OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY]) andReturnValue:@YES];
    [OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY withDataTaskError:OCMOCK_ANY]) andReturnValue:@YES];
    [OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY withHTTPError:OCMOCK_ANY]) andReturnValue:@YES];
    OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY withServiceError:OCMOCK_ANY])
    .andDo([self delegateShouldHandleResponseForRequestPassBlock]);
    // Stub and make request.
    [self stubSomeRequestWithClient:client].andReturn(200)
    .withBody([NSString stringWithFormat:@"{ \"%@\": \"unknown\" }", NBClientErrorCodeKey]);
    [client fetchPersonForClientUserWithCompletionHandler:[self delegateShouldHandleResponseForRequestFailBlock]];
    [self tearDownAsync];
}

@end