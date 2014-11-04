//
//  NBClientTests.m
//  NBClientTests
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBTestCase.h"

#import "FoundationAdditions.h"

#import "NBAuthenticator.h"
#import "NBClient.h"
#import "NBClient+People.h"

@interface NBClientTests : NBTestCase

@property (nonatomic, weak, readonly) NBClient *baseClientWithAuthenticator;
@property (nonatomic, weak, readonly) NBClient *baseClientWithTestToken;

- (void)assertCredential:(NBAuthenticationCredential *)credential;

@property (nonatomic, weak, readonly) NBClient *baseClientWithTestTokenAndMockDelegate;
@property (nonatomic, weak, readonly) NBClientResourceItemCompletionHandler delegateShouldHandleResponseForRequestFailBlock;
@property (nonatomic, weak, readonly) void (^delegateShouldHandleResponseForRequestPassBlock)(NSInvocation *);

- (LSStubRequestDSL *)stubFetchPersonForClientUserRequestWithClient:(NBClient *)client;

@end

@implementation NBClientTests

#pragma mark - Initialization

#pragma mark Helpers

- (NBClient *)baseClientWithAuthenticator
{
    NBAuthenticator *authenticator = [[NBAuthenticator alloc] initWithBaseURL:self.baseURL
                                                             clientIdentifier:self.clientIdentifier];
    return [[NBClient alloc] initWithNationSlug:self.nationSlug
                                  authenticator:authenticator
                               customURLSession:[NSURLSession sharedSession]
                  customURLSessionConfiguration:nil];
}
- (NBClient *)baseClientWithTestToken
{
    return [[NBClient alloc] initWithNationSlug:self.nationSlug
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

- (LSStubRequestDSL *)stubFetchPersonForClientUserRequestWithClient:(NBClient *)client
{
    return [self stubRequestWithMethod:@"GET" path:@"people/me" identifier:NSNotFound parameters:nil client:client];
}

// OCMProtocolMock allows the object to respond to all protocol method selectors,
// even the optional ones. This means there is additional boilerplate to explicitly
// stub as many methods as needed to reach the one we're testing.
- (void)stubDelegateShouldHandleResponseForRequestWithClient:(NBClient *)client
                                              untilTaskError:(BOOL)untilTaskError
                                              untilHTTPError:(BOOL)untilHTTPError
                                           untilServiceError:(BOOL)untilServiceError
{
    [OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY]) andReturnValue:@YES];
    if (untilTaskError) { return; }
    [OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY withDataTaskError:OCMOCK_ANY]) andReturnValue:@YES];
    if (untilHTTPError) { return; }
    [OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY withHTTPError:OCMOCK_ANY]) andReturnValue:@YES];
    if (untilServiceError) { return; }
    [OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY withServiceError:OCMOCK_ANY]) andReturnValue:@YES];
}

#pragma mark Tests

- (void)testDelegateShouldHandleResponseForRequest
{
    self.shouldUseHTTPStubbingOnce = YES;
    [self setUpAsync];
    NBClient *client = [self baseClientWithTestTokenAndMockDelegate];
    // Mock delegate and stub method.
    OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY])
    .andDo([self delegateShouldHandleResponseForRequestPassBlock]);
    // Stub and make request.
    [self stubFetchPersonForClientUserRequestWithClient:client].andReturn(200);
    [client fetchPersonForClientUserWithCompletionHandler:[self delegateShouldHandleResponseForRequestFailBlock]];
    [self tearDownAsync];
}

- (void)testDelegateShouldHandleResponseForRequestWithDataTaskError
{
    self.shouldUseHTTPStubbingOnce = YES;
    [self setUpAsync];
    NBClient *client = [self baseClientWithTestTokenAndMockDelegate];
    // Mock delegate and stub method.
    [self stubDelegateShouldHandleResponseForRequestWithClient:client untilTaskError:YES untilHTTPError:NO untilServiceError:NO];
    OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY withDataTaskError:OCMOCK_ANY])
    .andDo([self delegateShouldHandleResponseForRequestPassBlock]);
    // Stub and make request.
    [self stubFetchPersonForClientUserRequestWithClient:client].andFailWithError([NSError errorWithDomain:NBErrorDomain code:0 userInfo:nil]);
    [client fetchPersonForClientUserWithCompletionHandler:[self delegateShouldHandleResponseForRequestFailBlock]];
    [self tearDownAsync];
}

- (void)testDelegateShouldHandleResponseForRequestWithHTTPError
{
    self.shouldUseHTTPStubbingOnce = YES;
    [self setUpAsync];
    NBClient *client = [self baseClientWithTestTokenAndMockDelegate];
    // Mock delegate and stub method.
    [self stubDelegateShouldHandleResponseForRequestWithClient:client untilTaskError:NO untilHTTPError:YES untilServiceError:NO];
    OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY withHTTPError:OCMOCK_ANY])
    .andDo([self delegateShouldHandleResponseForRequestPassBlock]);
    // Stub and make request.
    [self stubFetchPersonForClientUserRequestWithClient:client].andReturn(404);
    [client fetchPersonForClientUserWithCompletionHandler:[self delegateShouldHandleResponseForRequestFailBlock]];
    [self tearDownAsync];
}

- (void)testDelegateShouldHandleResponseForRequestWithServiceError
{
    self.shouldUseHTTPStubbingOnce = YES;
    [self setUpAsync];
    NBClient *client = [self baseClientWithTestTokenAndMockDelegate];
    // Mock delegate and stub method.
    [self stubDelegateShouldHandleResponseForRequestWithClient:client untilTaskError:NO untilHTTPError:NO untilServiceError:YES];
    OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY withServiceError:OCMOCK_ANY])
    .andDo([self delegateShouldHandleResponseForRequestPassBlock]);
    // Stub and make request.
    [self stubFetchPersonForClientUserRequestWithClient:client].andReturn(200)
    .withBody([NSString stringWithFormat:@"{ \"%@\": \"unknown\" }", NBClientErrorCodeKey]);
    [client fetchPersonForClientUserWithCompletionHandler:[self delegateShouldHandleResponseForRequestFailBlock]];
    [self tearDownAsync];
}

- (void)testDelegateWillCreateDataTaskForRequest
{
    self.shouldUseHTTPStubbingOnce = YES;
    [self setUpAsync];
    NBClient *client = [self baseClientWithTestTokenAndMockDelegate];
    // Mock delegate and stub method.
    [self stubDelegateShouldHandleResponseForRequestWithClient:client untilTaskError:NO untilHTTPError:NO untilServiceError:NO];
    OCMStub([client.delegate client:client willCreateDataTaskForRequest:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [obj isKindOfClass:[NSMutableURLRequest class]];
    }]]);
    [self stubFetchPersonForClientUserRequestWithClient:client].andReturn(200);
    // Stub and make request.
    [client fetchPersonForClientUserWithCompletionHandler:^(NSDictionary *item, NSError *error) {
        OCMVerify([client.delegate client:client willCreateDataTaskForRequest:OCMOCK_ANY]);
        [self completeAsync];
    }];
    [self tearDownAsync];
}

- (void)testDelegateShouldAutomaticallyStartDataTask
{
    NBClient *client = [self baseClientWithTestToken];
    client.delegate = OCMProtocolMock(@protocol(NBClientDelegate));
    [OCMStub([client.delegate client:client shouldAutomaticallyStartDataTask:OCMOCK_ANY]) andReturnValue:@NO];
    NSURLSessionDataTask *task = [client fetchPersonForClientUserWithCompletionHandler:nil];
    XCTAssertNotNil(task, @"The task should be returned.");
    XCTAssertTrue(task.state == NSURLSessionTaskStateSuspended, @"The task should not have been automatically started.");
}

- (void)testDelegateDidParseJSONFromResponseForRequest
{
    self.shouldUseHTTPStubbingOnce = YES;
    [self setUpAsync];
    NBClient *client = [self baseClientWithTestTokenAndMockDelegate];
    // Mock delegate and stub method.
    [self stubDelegateShouldHandleResponseForRequestWithClient:client untilTaskError:NO untilHTTPError:NO untilServiceError:NO];
    OCMStub([client.delegate client:client didParseJSON:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [@{ @"person": @{} } nb_containsDictionary:obj];
    }] fromResponse:OCMOCK_ANY forRequest:OCMOCK_ANY]);
    [self stubFetchPersonForClientUserRequestWithClient:client].andReturn(200)
    .withBody(@"{ \"person\": {} }");
    // Stub and make request.
    [client fetchPersonForClientUserWithCompletionHandler:^(NSDictionary *item, NSError *error) {
        OCMVerify([client.delegate client:client didParseJSON:OCMOCK_ANY fromResponse:OCMOCK_ANY forRequest:OCMOCK_ANY]);
        [self completeAsync];
    }];
    [self tearDownAsync];
}

@end