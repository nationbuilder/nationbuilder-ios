//
//  NBClientTests.m
//  NBClientTests
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBTestCase.h"

#import "FoundationAdditions.h"

#import "NBAuthenticator.h"
#import "NBClient_Internal.h"
#import "NBClient+People.h"
#import "NBPaginationInfo.h"

@interface NBClientTests : NBTestCase

- (NBClient *)baseClientWithAuthenticator;
- (NBClient *)baseClientWithTestToken;

- (void)assertCredential:(NBAuthenticationCredential *)credential;

- (NBClient *)baseClientWithTestTokenAndMockDelegate;
- (NBClientResourceItemCompletionHandler)delegateShouldHandleResponseForRequestFailBlock;
- (void (^)(NSInvocation *))delegateShouldHandleResponseForRequestPassBlock;

- (LSStubRequestDSL *)stubFetchPersonForClientUserRequestWithClient:(NBClient *)client;
- (void)stubDelegateShouldHandleResponseForRequestWithClient:(NBClient *)client
                                              untilTaskError:(BOOL)untilTaskError
                                              untilHTTPError:(BOOL)untilHTTPError
                                           untilServiceError:(BOOL)untilServiceError;

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

- (void)testDelegatingDefaultURLSessionToClientDelegate
{
    // Given: no custom URL session.
    __block NBClient *client; dispatch_block_t initClient = ^{
        client = [[NBClient alloc] initWithNationSlug:self.nationSlug apiKey:self.testToken customBaseURL:self.baseURL
                                     customURLSession:nil customURLSessionConfiguration:nil];
    };
    // When: no client delegate.
    initClient();
    XCTAssertEqual(client.urlSession.delegate, client,
                   @"Client should be default session's delegate.");

    // When: assigning delegate immediately after initialization.
    initClient();
    client.delegate = OCMProtocolMock(@protocol(NBClientDelegate));
    XCTAssertEqual(client.urlSession.delegate, client.delegate,
                   @"Client should delegate default session to delegate.");
}

- (void)testTogglingIncludingKeyAsHeader
{
    if (self.shouldUseHTTPStubbing) { return NBLog(@"SKIPPING"); }
    [self setUpAsync];
    NBClient *client = [self baseClientWithTestToken];
    void (^testRequest)(dispatch_block_t) = ^(dispatch_block_t completionHandler) {
        [client fetchPersonForClientUserWithCompletionHandler:^(NSDictionary *item, NSError *error) {
            [self assertServiceError:error];
            completionHandler();
        }];
    };
    client.shouldIncludeKeyAsHeader = YES;
    testRequest(^{
        client.shouldIncludeKeyAsHeader = NO;
        testRequest(^{ [self completeAsync]; });
    });
    [self tearDownAsync];
}

// FIXME: Password grant type no longer supported.
- (void)x_testAsyncAuthenticatedInitialization
{
    if (self.shouldOnlyUseTestToken) { return NBLog(@"SKIPPING"); }
    [self setUpAsync];
    // Test credential persistence across initializations.
    void (^testCredentialPersistence)(void) = ^{
        NBClient *otherClient = [self baseClientWithAuthenticator];
        NSURLSessionDataTask *task =
        [otherClient.authenticator
         authenticateWithUserName:self.userEmailAddress password:self.userPassword clientSecret:self.clientSecret
         completionHandler:^(NBAuthenticationCredential *credential, NSError *error) {
             [self assertServiceError:error];
             [self assertCredential:credential];
         }];
        XCTAssertNil(task,
                     @"Saved credential should have been fetched to obviate authenticating against service.");
    };
    // Test authentication.
    NBClient *client = [self baseClientWithAuthenticator];
    XCTAssertNotNil(client.authenticator,
                    @"Client should have authenticator.");
    NSString *credentialIdentifier = client.authenticator.credentialIdentifier;
    [NBAuthenticationCredential deleteCredentialWithIdentifier:credentialIdentifier];
    [client.authenticator
     authenticateWithUserName:self.userEmailAddress password:self.userPassword clientSecret:self.clientSecret
     completionHandler:^(NBAuthenticationCredential *credential, NSError *error) {
         [self assertServiceError:error];
         [self assertCredential:credential];
         client.apiKey = credential.accessToken;
         testCredentialPersistence();
         [self completeAsync];
     }];
    [self tearDownAsync];
}

#pragma mark - Mutation

#pragma mark Helpers

- (NSURL *)getSomeRequestURLForClient:(NBClient *)client {
    if (self.shouldUseHTTPStubbing) {
        // NOTE: There won't be a file, but request will be cancelled.
        [self stubRequestUsingFileDataWithMethod:@"GET" pathFormat:@"people/me" pathVariables:nil queryParameters:nil variant:nil
                                          client:client];
    }
    NBClientResourceItemCompletionHandler completion = ^(NSDictionary *item, NSError *error) {};
    NSURLSessionDataTask *task = [client fetchPersonForClientUserWithCompletionHandler:completion];
    [task cancel];
    return task.currentRequest.URL;
}

#pragma mark Tests

- (void)testConfiguringAPIVersion
{
    NBClient *client = self.baseClientWithTestToken;
    client.apiVersion = [client.apiVersion stringByAppendingString:@"0"];
    NSString *path = [self getSomeRequestURLForClient:client].path;
    XCTAssertTrue([path rangeOfString:client.apiVersion].location != NSNotFound,
                  @"Version string in all future request URLs should have been updated.");
}

- (void)testConfigurationAPIKey
{
    NBClient *client = self.baseClientWithTestToken;
    client.apiKey = [client.apiKey stringByAppendingString:@"0"];
    NSString *query = [self getSomeRequestURLForClient:client].query;
    XCTAssertTrue([query rangeOfString:client.apiKey].location != NSNotFound,
                  @"Key in all future request URLs should have been updated.");
}

- (void)testTaskHandlingOfPaginationInfo
{
    if (self.shouldUseHTTPStubbing) { return NBLog(@"SKIPPING"); }
    [self setUpAsync];
    [self setUpSharedClient];
    __block NSUInteger expectationCount = 2; dispatch_block_t complete = ^{
        expectationCount -= 1;
        if (expectationCount == 0) { [self completeAsync]; }
    };

    [self.client
     fetchByResourceSubPath:@"/people" withParameters:nil customResultsKey:nil paginationInfo:nil
     completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
         [self assertServiceError:error];
         [self assertPeopleArray:items];
         XCTAssertTrue(paginationInfo.numberOfItemsPerPage > 0,
                       @"Pagination info should exist.");
         complete();
     }];
    
    NSDictionary *paginationParameters = @{ NBClientPaginationLimitKey: @5, NBClientPaginationTokenOptInKey: @1 };
    NBPaginationInfo *requestPaginationInfo = [[NBPaginationInfo alloc] initWithDictionary:paginationParameters legacy:NO];
    NSUInteger oldCurrentPageNumber = requestPaginationInfo.currentPageNumber;
    [self.client
     fetchByResourceSubPath:@"/people" withParameters:nil customResultsKey:nil paginationInfo:requestPaginationInfo
     completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
         [self assertServiceError:error];
         [self assertPeopleArray:items];
         XCTAssertEqual(paginationInfo.numberOfItemsPerPage, [paginationParameters[NBClientPaginationLimitKey] unsignedIntegerValue],
                        @"Pagination info should be persisted.");
         XCTAssertEqual(paginationInfo.currentPageNumber, oldCurrentPageNumber + 1,
                        @"Pagination info should be updated.");
         complete();
     }];

    [self tearDownAsync];
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
    return [self stubRequestWithMethod:@"GET" pathFormat:@"people/me" pathVariables:nil queryParameters:nil client:client];
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
    [self setUpAsyncWithHTTPStubbing:YES];
    NBClient *client = [self baseClientWithTestTokenAndMockDelegate];
    // Mock delegate and stub method.
    [OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY])
     andDo:[self delegateShouldHandleResponseForRequestPassBlock]];
    // Stub and make request.
    [self stubFetchPersonForClientUserRequestWithClient:client].andReturn(200);
    [client fetchPersonForClientUserWithCompletionHandler:[self delegateShouldHandleResponseForRequestFailBlock]];
    [self tearDownAsync];
}

- (void)testDelegateShouldHandleResponseForRequestWithDataTaskError
{
    [self setUpAsyncWithHTTPStubbing:YES];
    NBClient *client = [self baseClientWithTestTokenAndMockDelegate];
    // Mock delegate and stub method.
    [self stubDelegateShouldHandleResponseForRequestWithClient:client untilTaskError:YES untilHTTPError:NO untilServiceError:NO];
    [OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY withDataTaskError:OCMOCK_ANY])
     andDo:[self delegateShouldHandleResponseForRequestPassBlock]];
    // Stub and make request.
    [self stubFetchPersonForClientUserRequestWithClient:client].andFailWithError([NSError errorWithDomain:NBErrorDomain code:0 userInfo:nil]);
    [client fetchPersonForClientUserWithCompletionHandler:[self delegateShouldHandleResponseForRequestFailBlock]];
    [self tearDownAsync];
}

- (void)testDelegateShouldHandleResponseForRequestWithHTTPError
{
    [self setUpAsyncWithHTTPStubbing:YES];
    NBClient *client = [self baseClientWithTestTokenAndMockDelegate];
    // Mock delegate and stub method.
    [self stubDelegateShouldHandleResponseForRequestWithClient:client untilTaskError:NO untilHTTPError:YES untilServiceError:NO];
    [OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY withHTTPError:OCMOCK_ANY])
     andDo:([self delegateShouldHandleResponseForRequestPassBlock])];
    // Stub and make request.
    [self stubFetchPersonForClientUserRequestWithClient:client].andReturn(404);
    [client fetchPersonForClientUserWithCompletionHandler:[self delegateShouldHandleResponseForRequestFailBlock]];
    [self tearDownAsync];
}

- (void)testDelegateShouldHandleResponseForRequestWithServiceError
{
    [self setUpAsyncWithHTTPStubbing:YES];
    NBClient *client = [self baseClientWithTestTokenAndMockDelegate];
    // Mock delegate and stub method.
    [self stubDelegateShouldHandleResponseForRequestWithClient:client untilTaskError:NO untilHTTPError:NO untilServiceError:YES];
    [OCMStub([client.delegate client:client shouldHandleResponse:OCMOCK_ANY forRequest:OCMOCK_ANY withServiceError:OCMOCK_ANY])
     andDo:[self delegateShouldHandleResponseForRequestPassBlock]];
    // Stub and make request.
    [self stubFetchPersonForClientUserRequestWithClient:client].andReturn(200)
    .withBody([NSString stringWithFormat:@"{ \"%@\": \"unknown\" }", NBClientErrorCodeKey]);
    [client fetchPersonForClientUserWithCompletionHandler:[self delegateShouldHandleResponseForRequestFailBlock]];
    [self tearDownAsync];
}

- (void)testDelegateWillCreateDataTaskForRequest
{
    [self setUpAsyncWithHTTPStubbing:YES];
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
    NSURLSessionDataTask *task = [client fetchPersonForClientUserWithCompletionHandler:^(NSDictionary *item, NSError *error) {}];
    XCTAssertNotNil(task, @"The task should be returned.");
    XCTAssertTrue(task.state == NSURLSessionTaskStateSuspended, @"The task should not have been automatically started.");
}

- (void)testDelegateDidParseJSONFromResponseForRequest
{
    [self setUpAsyncWithHTTPStubbing:YES];
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
