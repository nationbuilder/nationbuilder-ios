//
//  NBTestCase.h
//  NBClient
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>
#undef andReturn
#import <Nocilla/Nocilla.h>

@class NBClient;
@class NBPaginationInfo;

@interface NBTestCase : XCTestCase

@property (nonatomic, readonly) NSString *nationSlug;
@property (nonatomic, readonly) NSURL *baseURL;
@property (nonatomic, readonly) NSString *baseURLString;

@property (nonatomic, readonly) NSString *testToken;
@property (nonatomic, readonly) NSString *clientIdentifier;
@property (nonatomic, readonly) NSString *clientSecret;
@property (nonatomic, readonly) NSString *userEmailAddress;
@property (nonatomic, readonly) NSUInteger userIdentifier;
@property (nonatomic, readonly) NSString *userPassword;

@property (nonatomic, readonly) NBClient *client;

@property (nonatomic, readonly) BOOL shouldUseHTTPStubbing;
@property (nonatomic, readonly) BOOL shouldOnlyUseTestToken; // This may be temporary.
@property (nonatomic) BOOL shouldUseHTTPStubbingOnce;

- (void)setUpSharedClient;
- (LSStubRequestDSL *)stubRequestWithMethod:(NSString *)method
                                       path:(NSString *)path
                                 identifier:(NSUInteger)identifier
                                 parameters:(NSDictionary *)parameters
                                     client:(NBClient *)client;
- (LSStubResponseDSL *)stubRequestUsingFileDataWithMethod:(NSString *)method
                                                     path:(NSString *)path
                                               identifier:(NSUInteger)identifier
                                               parameters:(NSDictionary *)parameters; // Convenience.
- (LSStubResponseDSL *)stubRequestUsingFileDataWithMethod:(NSString *)method
                                                     path:(NSString *)path
                                               identifier:(NSUInteger)identifier
                                               parameters:(NSDictionary *)parameters
                                                   client:(NBClient *)client;

- (void)assertPaginationInfo:(NBPaginationInfo *)paginationInfo
    withPaginationParameters:(NSDictionary *)paginationParameters;
- (void)assertServiceError:(NSError *)error;
- (void)assertSessionDataTask:(NSURLSessionDataTask *)task;

- (void)stubInfoFileBundleResourcePathForOperations:(void (^)(void))operationsBlock;

// Async test helpers on top of XCTestExpectation.

@property (nonatomic) NSTimeInterval asyncTimeoutInterval;
@property (nonatomic, weak, readonly) XCTestExpectation *mainExpectation;

- (void)setUpAsync;
- (void)setUpAsyncWithHTTPStubbing:(BOOL)shouldUseHTTPStubbing;

- (void)tearDownAsync;

- (void)completeAsync;

@end
