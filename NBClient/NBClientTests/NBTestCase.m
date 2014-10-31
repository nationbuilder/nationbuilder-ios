//
//  NBTestCase.m
//  NBClient
//
//  Created by Peng Wang on 7/11/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBTestCase.h"

#import "FoundationAdditions.h"
#import "NBAuthenticator.h"
#import "NBClient.h"
#import "NBPaginationInfo.h"

// These are additional client info keys for certain tests against a local environment.
NSString * const NBInfoShouldUseHTTPStubbingKey = @"Should Use HTTP Stubbing";
NSString * const NBInfoUserEmailAddressKey = @"User Email Address";
NSString * const NBInfoUserIdentifierKey = @"User ID";
NSString * const NBInfoUserPasswordKey = @"User Password";

@interface NBTestCase ()

@property (nonatomic) BOOL didCallBack;

@property (nonatomic, strong, readwrite) NSString *nationName;
@property (nonatomic, strong, readwrite) NSURL *baseURL;
@property (nonatomic, strong, readwrite) NSString *baseURLString;

@property (nonatomic, strong, readwrite) NSString *testToken;
@property (nonatomic, strong, readwrite) NSString *clientIdentifier;
@property (nonatomic, strong, readwrite) NSString *clientSecret;
@property (nonatomic, strong, readwrite) NSString *userEmailAddress;
@property (nonatomic, readwrite) NSUInteger userIdentifier;
@property (nonatomic, strong, readwrite) NSString *userPassword;

@property (nonatomic, strong, readwrite) NBClient *client;

+ (NSDictionary *)dictionaryWithContentsOfInfoFile;

+ (BOOL)shouldUseHTTPStubbing;

@end

@implementation NBTestCase

+ (void)setUp
{
    [super setUp];
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
    NSDictionary *info = self.class.dictionaryWithContentsOfInfoFile;
    self.nationName = info[NBInfoNationNameKey];
    NSAssert(self.nationName, @"Missing environment arguments for tests.");
    self.baseURLString = [NSString stringWithFormat:info[NBInfoBaseURLFormatKey], self.nationName];
    self.baseURL = [NSURL URLWithString:self.baseURLString];
    self.testToken = info[NBInfoTestTokenKey];
    self.clientIdentifier = info[NBInfoClientIdentifierKey];
    self.clientSecret = info[NBInfoClientSecretKey];
    self.userEmailAddress = info[NBInfoUserEmailAddressKey];
    self.userIdentifier = [info[NBInfoUserIdentifierKey] integerValue];
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
        pathName = [NBInfoFileName stringByAppendingString:@"-Local"];
#endif
        pathName = pathName ?: NBInfoFileName;
        info = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:self] pathForResource:pathName ofType:@"plist"]];
    });
    return info;
}

+ (BOOL)shouldUseHTTPStubbing
{
    return self.dictionaryWithContentsOfInfoFile[NBInfoShouldUseHTTPStubbingKey];
}

- (BOOL)shouldUseHTTPStubbing
{
    return [self.class shouldUseHTTPStubbing];
}

- (BOOL)shouldOnlyUseTestToken
{
    return !self.userPassword;
}

- (LSStubRequestDSL *)stubRequestWithMethod:(NSString *)method
                                       path:(NSString *)path
                                 identifier:(NSUInteger)identifier
                                 parameters:(NSDictionary *)parameters
                                     client:(NBClient *)client
{
    client = client ?: self.client;
    NSURLComponents *components = [NSURLComponents componentsWithURL:self.baseURL resolvingAgainstBaseURL:NO];
    components.path = [NSString stringWithFormat:@"/api/%@/%@", client.apiVersion, path];
    BOOL hasIdentifier = identifier != NSNotFound;
    if (hasIdentifier) {
        components.path = [components.path stringByAppendingString:[NSString stringWithFormat:@"/%lu", identifier]];
    }
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    mutableParameters[@"access_token"] = client.apiKey;
    components.query = [mutableParameters nb_queryStringWithEncoding:NSASCIIStringEncoding
                                         skipPercentEncodingPairKeys:[NSSet setWithObject:@"email"]
                                          charactersToLeaveUnescaped:nil];
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    headers[@"Accept"] = @"application/json";
    if ([method isEqual:@"POST"] || [method isEqual:@"PUT"]) {
        headers[@"Content-Type"] = @"application/json";
    }
    NBLog(@"STUB: %@", components.URL.absoluteString);
    return stubRequest(method, components.URL.absoluteString).withHeaders(headers);
}

- (LSStubResponseDSL *)stubRequestUsingFileDataWithMethod:(NSString *)method
                                                     path:(NSString *)path
                                               identifier:(NSUInteger)identifier
                                               parameters:(NSDictionary *)parameters
{
    BOOL hasIdentifier = identifier != NSNotFound;
    // Get file name that's conventionally composed from path, identifier existence, and method.
    NSString *fileName = [NSString stringWithFormat:@"%@%@_%@",
                          [path stringByReplacingOccurrencesOfString:@"/" withString:@"_"],
                          (hasIdentifier ? @"_id" : @""),
                          method.lowercaseString];
    NSData *data = [NSData dataWithContentsOfFile:
                    [[NSBundle bundleForClass:self.class] pathForResource:fileName ofType:@"txt"]];
    return ([self stubRequestWithMethod:method path:path identifier:identifier parameters:parameters client:nil]
            .andReturnRawResponse(data));
}

- (void)setUpSharedClient
{
    // We need to use the shared session because we need to be in an application
    // for an app-specific cache.
    __block NSString *apiKey;
    if (!self.shouldOnlyUseTestToken) {
        NBAuthenticator *authenticator = [[NBAuthenticator alloc] initWithBaseURL:self.baseURL
                                                                 clientIdentifier:self.clientIdentifier];
        NSURLSessionDataTask *task = [authenticator
                                      authenticateWithUserName:self.userEmailAddress
                                      password:self.userPassword
                                      clientSecret:self.clientSecret
                                      completionHandler:^(NBAuthenticationCredential *credential, NSError *error) {
                                          apiKey = credential.accessToken;
                                      }];
        NSAssert(!task, @"Test case requires saved authentication credential. Re-authenticating should not happen.");
    } else {
        apiKey = self.testToken;
    }
    self.client = [[NBClient alloc] initWithNationName:self.nationName
                                                apiKey:apiKey
                                         customBaseURL:self.baseURL
                                      customURLSession:[NSURLSession sharedSession]
                         customURLSessionConfiguration:nil];
}

- (void)assertPaginationInfo:(NBPaginationInfo *)paginationInfo
    withPaginationParameters:(NSDictionary *)paginationParameters
{
    XCTAssertTrue(paginationInfo.currentPageNumber == [paginationParameters[NBClientCurrentPageNumberKey] unsignedIntegerValue],
                  @"Pagination info should be properly populated.");
    XCTAssertTrue(paginationInfo.numberOfItemsPerPage == [paginationParameters[NBClientNumberOfItemsPerPageKey] unsignedIntegerValue],
                  @"Pagination info should be properly populated.");
    XCTAssertTrue(paginationInfo.numberOfTotalPages > 0,
                  @"Pagination info should be properly populated.");
}

- (void)assertServiceError:(NSError *)error
{
    if (!error || error.domain != NBErrorDomain) {
        return;
    }
    if (error.code == NBClientErrorCodeService) {
        XCTFail(@"People service returned error %@", error);
    }
}

- (void)assertSessionDataTask:(NSURLSessionDataTask *)task
{
    XCTAssertTrue(task && task.state == NSURLSessionTaskStateRunning,
                  @"Client should have created and ran task.");
}

#pragma mark - Async API

- (void)setUpAsync
{
    self.asyncTimeoutInterval = 10.0f;
    self.didCallBack = NO;
}

- (void)tearDownAsync
{
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:self.asyncTimeoutInterval];
    while (!self.didCallBack && timeoutDate.timeIntervalSinceNow > 0.0f) {
        [[NSRunLoop currentRunLoop] runMode:NSRunLoopCommonModes beforeDate:timeoutDate];
    }
    if (!self.didCallBack) {
        XCTFail(@"Async test timed out.");
    }
    if (self.shouldUseHTTPStubbing) {
        [[LSNocilla sharedInstance] clearStubs];
    }
}

- (void)completeAsync
{
    self.didCallBack = YES;
}

@end
