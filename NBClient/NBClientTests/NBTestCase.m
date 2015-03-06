//
//  NBTestCase.m
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import "NBTestCase.h"

#import "FoundationAdditions.h"
#import "NBAuthenticator.h"
#import "NBClient.h"
#import "NBPaginationInfo.h"

// These are additional client info keys for certain tests against a local environment.
NSString * const NBInfoShouldUseHTTPStubbingKey = @"Should Use HTTP Stubbing";
NSString * const NBInfoSupporterIdentifierKey = @"Supporter ID";
NSString * const NBInfoUserEmailAddressKey = @"User Email Address";
NSString * const NBInfoUserIdentifierKey = @"User ID";
NSString * const NBInfoUserPasswordKey = @"User Password";

@interface NBTestCase ()

@property (nonatomic, copy, readwrite) NSString *nationSlug;
@property (nonatomic, readwrite) NSURL *baseURL;
@property (nonatomic, copy, readwrite) NSString *baseURLString;

@property (nonatomic, copy, readwrite) NSString *testToken;
@property (nonatomic, copy, readwrite) NSString *clientIdentifier;
@property (nonatomic, copy, readwrite) NSString *clientSecret;
@property (nonatomic, readwrite) NSUInteger supporterIdentifier;
@property (nonatomic, copy, readwrite) NSString *userEmailAddress;
@property (nonatomic, readwrite) NSUInteger userIdentifier;
@property (nonatomic, copy, readwrite) NSString *userPassword;

@property (nonatomic, readwrite) NBClient *client;

@property (nonatomic, weak, readwrite) XCTestExpectation *mainExpectation;

+ (NSDictionary *)dictionaryWithContentsOfInfoFile;

+ (BOOL)shouldUseHTTPStubbing;

@end

@implementation NBTestCase

+ (void)setUp
{
    [super setUp];
    // NOTE: Comment out to get more logging.
    [NBClient updateLoggingToLevel:NBLogLevelWarning];
    if ([self shouldUseHTTPStubbing]) {
        [[LSNocilla sharedInstance] start];
    }
}

+ (void)tearDown
{
    [super tearDown];
    if ([self shouldUseHTTPStubbing]) {
        [[LSNocilla sharedInstance] stop];
    }
}

- (void)setUp
{
    [super setUp];
    // Provide default config for test cases.
    NSDictionary *info = [self.class dictionaryWithContentsOfInfoFile];
    self.nationSlug = info[NBInfoNationSlugKey];
    NSAssert(self.nationSlug, @"Missing environment arguments for tests.");
    self.baseURLString = [NSString stringWithFormat:info[NBInfoBaseURLFormatKey], self.nationSlug];
    self.baseURL = [NSURL URLWithString:self.baseURLString];
    self.testToken = info[NBInfoTestTokenKey];
    self.clientIdentifier = info[NBInfoClientIdentifierKey];
    self.clientSecret = info[NBInfoClientSecretKey];
    self.supporterIdentifier = [info[NBInfoSupporterIdentifierKey] unsignedIntegerValue];
    self.userEmailAddress = info[NBInfoUserEmailAddressKey];
    self.userIdentifier = [info[NBInfoUserIdentifierKey] unsignedIntegerValue];
    self.userPassword = info[NBInfoUserPasswordKey];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - Helpers

+ (NSDictionary *)dictionaryWithContentsOfInfoFile
{
    static NSDictionary *info;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *pathName;
#if DEBUG
        // NOTE: Comment out to run CI tests.
        pathName = [NBInfoFileName stringByAppendingString:@"-Local"];
#endif
        pathName = pathName ?: NBInfoFileName;
        info = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:self] pathForResource:pathName ofType:@"plist"]];
    });
    return info;
}

+ (BOOL)shouldUseHTTPStubbing
{
    return [[self dictionaryWithContentsOfInfoFile][NBInfoShouldUseHTTPStubbingKey] boolValue];
}

- (BOOL)shouldUseHTTPStubbing
{
    return [self.class shouldUseHTTPStubbing];
}

- (BOOL)shouldOnlyUseTestToken
{
    return !self.userPassword;
}

- (void)stubInfoFileBundleResourcePathForOperations:(void (^)(void))operationsBlock
{
    id bundleMock = OCMClassMock([NSBundle class]);
    [OCMStub([bundleMock mainBundle]) andReturn:bundleMock];
    [OCMStub([bundleMock pathForResource:NBInfoFileName ofType:@"plist"])
     andReturn:[[NSBundle bundleForClass:self.class] pathForResource:NBInfoFileName ofType:@"plist"]];
    
    operationsBlock();
    
    [bundleMock stopMocking];
}

- (LSStubRequestDSL *)stubRequestWithMethod:(NSString *)method
                                 pathFormat:(NSString *)pathFormat
                              pathVariables:(NSDictionary *)pathVariables
                            queryParameters:(NSDictionary *)queryParameters
                                     client:(NBClient *)client
{
    static NSString *finalPathFormat = @"/api/%@/%@";
    client = client ?: self.client;
    // We need to build our path.
    NSURLComponents *components = [NSURLComponents componentsWithURL:client.baseURL resolvingAgainstBaseURL:NO];
    NSString *path = pathFormat;
    if (pathVariables) {
        NSMutableArray *pathComponents = pathFormat.pathComponents.mutableCopy;
        for (NSString *variableName in pathVariables.allKeys) {
            NSUInteger index = [pathComponents indexOfObject:[NSString stringWithFormat:@":%@", variableName]];
            [pathComponents replaceObjectAtIndex:index withObject:[NSString stringWithFormat:@"%@", pathVariables[variableName]]];
        }
        path = [NSString pathWithComponents:pathComponents];
    }
    components.path = [NSString stringWithFormat:finalPathFormat, client.apiVersion, path];
    // And we need to build our query.
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionaryWithDictionary:queryParameters];
    mutableParameters[@"access_token"] = mutableParameters[@"access_token"] ?: client.apiKey;
    components.percentEncodedQuery = [mutableParameters nb_queryString];
    // Check our URL.
    NBLog(@"STUB: %@", components.URL.absoluteString);
    // And our headers.
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    headers[@"Accept"] = @"application/json";
    if ([method isEqual:@"POST"] || [method isEqual:@"PUT"]) {
        headers[@"Content-Type"] = @"application/json";
    }
    // Finally, send it to Nocilla.
    return stubRequest(method, components.URL.absoluteString).withHeaders(headers);
}

- (LSStubResponseDSL *)stubRequestUsingFileDataWithMethod:(NSString *)method
                                                     path:(NSString *)path
                                          queryParameters:(NSDictionary *)queryParameters
{
    return [self stubRequestUsingFileDataWithMethod:method pathFormat:path pathVariables:nil queryParameters:queryParameters];
}

- (LSStubResponseDSL *)stubRequestUsingFileDataWithMethod:(NSString *)method
                                               pathFormat:(NSString *)pathFormat
                                            pathVariables:(NSDictionary *)pathVariables
                                          queryParameters:(NSDictionary *)queryParameters
{
    return [self stubRequestUsingFileDataWithMethod:method pathFormat:pathFormat pathVariables:pathVariables queryParameters:queryParameters variant:nil client:nil];
}
- (LSStubResponseDSL *)stubRequestUsingFileDataWithMethod:(NSString *)method
                                               pathFormat:(NSString *)pathFormat
                                            pathVariables:(NSDictionary *)pathVariables
                                          queryParameters:(NSDictionary *)queryParameters
                                                  variant:(NSString *)variant
                                                   client:(NBClient *)client
{
    // NOTE: We purposefully do not include dynamic data in the file names, for easy maintenance.
    // Get file name that's conventionally composed from path and method.
    NSString *fileName = [NSString stringWithFormat:@"%@%@_%@",
                          [[pathFormat
                            stringByReplacingOccurrencesOfString:@"/" withString:@"_"]
                           stringByReplacingOccurrencesOfString:@":" withString:@""],
                          (variant ? [NSString stringWithFormat:@"_%@", variant] : @""),
                          method.lowercaseString];
    NSData *data = [NSData dataWithContentsOfFile:
                    [[NSBundle bundleForClass:self.class] pathForResource:fileName ofType:@"txt"]];
    return ([self stubRequestWithMethod:method pathFormat:pathFormat pathVariables:pathVariables queryParameters:queryParameters client:client]
            .andReturnRawResponse(data));
}

- (void)setUpSharedClient
{
    // We need to use the shared session because we need to be in an application
    // for an app-specific cache.
    __block NSString *apiKey;
    BOOL shouldUseTestToken = self.shouldOnlyUseTestToken;
    if (!shouldUseTestToken) {
        NBAuthenticator *authenticator = [[NBAuthenticator alloc] initWithBaseURL:self.baseURL
                                                                 clientIdentifier:self.clientIdentifier];
        NSURLSessionDataTask *task = [authenticator
                                      authenticateWithUserName:self.userEmailAddress
                                      password:self.userPassword
                                      clientSecret:self.clientSecret
                                      completionHandler:^(NBAuthenticationCredential *credential, NSError *error) {
                                          apiKey = credential.accessToken;
                                      }];
        if (task) {
            NBLog(@"WARNING: Test case requires saved authentication credential. Re-authenticating should not happen.");
            // Fallback to using test token.
            [task cancel];
            shouldUseTestToken = YES;
        }
    }
    if (shouldUseTestToken) {
        // NOTE: When using HTTP-stubbing, the authenticity of test token is not
        // tested and does not matter.
        apiKey = self.testToken;
    }
    self.client = [[NBClient alloc] initWithNationSlug:self.nationSlug
                                                apiKey:apiKey
                                         customBaseURL:self.baseURL
                                      customURLSession:[NSURLSession sharedSession]
                         customURLSessionConfiguration:nil];
}

- (void)assertPaginationInfo:(NBPaginationInfo *)paginationInfo
    withPaginationParameters:(NSDictionary *)paginationParameters
{
    if (paginationInfo.isLegacy) {
        XCTAssertEqual(paginationInfo.currentPageNumber, [paginationParameters[NBClientCurrentPageNumberKey] unsignedIntegerValue],
                       @"Pagination info should be properly populated.");
        XCTAssertEqual(paginationInfo.numberOfItemsPerPage, [paginationParameters[NBClientNumberOfItemsPerPageKey] unsignedIntegerValue],
                       @"Pagination info should be properly populated.");
        XCTAssertTrue(paginationInfo.numberOfTotalPages > 0,
                      @"Pagination info should be properly populated.");
    } else {
        XCTAssertEqual(paginationInfo.numberOfItemsPerPage, [paginationParameters[NBClientPaginationLimitKey] unsignedIntegerValue],
                       @"Pagination info should be properly populated.");
        XCTAssertNotNil(paginationInfo.nextPageURLString,
                        @"Pagination info should be properly populated.");
    }
}

- (void)assertServiceError:(NSError *)error
{
    if (!error || error.domain != NBErrorDomain) {
        return;
    }
    XCTFail(@"NationBuilder service returned error %@", error);
}

- (void)assertSessionDataTask:(NSURLSessionDataTask *)task
{
    XCTAssertTrue(task && task.state == NSURLSessionTaskStateRunning,
                  @"Client should have created and ran task.");
}

#pragma mark - Async Test Helpers

- (void)setUpAsync
{
    [self setUpAsyncWithHTTPStubbing:NO];
}

- (void)setUpAsyncWithHTTPStubbing:(BOOL)shouldUseHTTPStubbing
{
    // NOTE: Override after this function call for the test if desired.
    self.asyncTimeoutInterval = 10.0f;
    self.shouldUseHTTPStubbingOnce = shouldUseHTTPStubbing;
    if (self.shouldUseHTTPStubbingOnce) {
        [[LSNocilla sharedInstance] start];
    }
    self.mainExpectation = [self expectationWithDescription:@"main"];
}

- (void)tearDownAsync
{
    [self waitForExpectationsWithTimeout:self.asyncTimeoutInterval handler:^(NSError *error) {
        if (self.shouldUseHTTPStubbingOnce) {
            self.shouldUseHTTPStubbingOnce = NO;
            [[LSNocilla sharedInstance] stop];
        } else if (self.shouldUseHTTPStubbing) {
            [[LSNocilla sharedInstance] clearStubs];
        }
    }];
}

- (void)completeAsync
{
    [self.mainExpectation fulfill];
}

@end
