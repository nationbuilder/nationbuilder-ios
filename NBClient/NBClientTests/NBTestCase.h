//
//  NBTestCase.h
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>
#undef andReturn
#import <Nocilla/Nocilla.h>

@class NBClient;
@class NBPaginationInfo;

@interface NBTestCase : XCTestCase

@property (nonatomic, copy, readonly) NSString *nationSlug;
@property (nonatomic, copy, readonly) NSURL *baseURL;
@property (nonatomic, copy, readonly) NSString *baseURLString;

@property (nonatomic, copy, readonly) NSString *testToken;
@property (nonatomic, copy, readonly) NSString *clientIdentifier;
@property (nonatomic, copy, readonly) NSString *clientSecret;
@property (nonatomic, readonly) NSUInteger supporterIdentifier;
@property (nonatomic, copy, readonly) NSString *userEmailAddress;
@property (nonatomic, readonly) NSUInteger userIdentifier;
@property (nonatomic, copy, readonly) NSString *userPassword;

@property (nonatomic, readonly) NBClient *client;

@property (nonatomic, readonly) BOOL shouldUseHTTPStubbing;
@property (nonatomic, readonly) BOOL shouldOnlyUseTestToken; // This may be temporary.
@property (nonatomic) BOOL shouldUseHTTPStubbingOnce;

- (void)setUpSharedClient;
// Partial stubbing method for ad-hoc stubbing.
- (LSStubRequestDSL *)stubRequestWithMethod:(NSString *)method
                                 pathFormat:(NSString *)pathFormat
                              pathVariables:(NSDictionary *)pathVariables
                            queryParameters:(NSDictionary *)queryParameters
                                     client:(NBClient *)client;
// Convenience full stubbing method for the simplest requests.
- (LSStubResponseDSL *)stubRequestUsingFileDataWithMethod:(NSString *)method
                                                     path:(NSString *)path
                                          queryParameters:(NSDictionary *)queryParameters;
// Convenience full stubbing method if test-specific clients aren't needed.
- (LSStubResponseDSL *)stubRequestUsingFileDataWithMethod:(NSString *)method
                                               pathFormat:(NSString *)pathFormat
                                            pathVariables:(NSDictionary *)pathVariables
                                          queryParameters:(NSDictionary *)queryParameters;
// Otherwise this is the de-facto, full stubbing method.
- (LSStubResponseDSL *)stubRequestUsingFileDataWithMethod:(NSString *)method
                                               pathFormat:(NSString *)pathFormat
                                            pathVariables:(NSDictionary *)pathVariables
                                          queryParameters:(NSDictionary *)queryParameters
                                                  variant:(NSString *)variant // Custom file distinguisher for atypical endpoints.
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
