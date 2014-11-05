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

@property (nonatomic, strong, readonly) NSString *nationSlug;
@property (nonatomic, strong, readonly) NSURL *baseURL;
@property (nonatomic, strong, readonly) NSString *baseURLString;

@property (nonatomic, strong, readonly) NSString *testToken;
@property (nonatomic, strong, readonly) NSString *clientIdentifier;
@property (nonatomic, strong, readonly) NSString *clientSecret;
@property (nonatomic, strong, readonly) NSString *userEmailAddress;
@property (nonatomic, readonly) NSUInteger userIdentifier;
@property (nonatomic, strong, readonly) NSString *userPassword;

@property (nonatomic, strong, readonly) NBClient *client;

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

// Async test helpers on top of XCTestExpectation.

@property (nonatomic) NSTimeInterval asyncTimeoutInterval;
@property (nonatomic, weak, readonly) XCTestExpectation *mainExpectation;

- (void)setUpAsync;
- (void)setUpAsyncWithHTTPStubbing:(BOOL)shouldUseHTTPStubbing;

- (void)tearDownAsync;

- (void)completeAsync;

@end
