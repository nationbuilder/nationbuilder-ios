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

@interface NBTestCase ()

@property (nonatomic) BOOL didCallBack;

@property (nonatomic, strong, readwrite) NSString *nationName;
@property (nonatomic, strong, readwrite) NSURL *baseURL;
@property (nonatomic, strong, readwrite) NSString *baseURLString;

@property (nonatomic, strong, readwrite) NSString *testToken;
@property (nonatomic, strong, readwrite) NSString *clientIdentifier;
@property (nonatomic, strong, readwrite) NSString *userEmailAddress;
@property (nonatomic, readwrite) NSUInteger userIdentifier;
@property (nonatomic, strong, readwrite) NSString *userPassword;

@property (nonatomic, strong, readwrite) NBClient *client;

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
    // NOTE: The reason we're still using launch-argument-based configurationis
    // because there is still hope that the xcodebuild command can leverage it.
    NSUserDefaults *launchArguments = [NSUserDefaults standardUserDefaults];
    self.nationName = [launchArguments stringForKey:@"NBNationName"];
    NSAssert(self.nationName, @"Missing environment arguments for tests.");
    self.baseURLString = [NSString stringWithFormat:[launchArguments stringForKey:@"NBBaseURLFormat"], self.nationName];
    self.baseURL = [NSURL URLWithString:self.baseURLString];
    self.testToken = [launchArguments stringForKey:@"NBTestToken"];
    self.clientIdentifier = [launchArguments stringForKey:@"NBClientIdentifier"];
    self.userEmailAddress = [launchArguments stringForKey:@"NBUserEmailAddress"];
    self.userIdentifier = [launchArguments integerForKey:@"NBUserIdentifier"];
    self.userPassword = [launchArguments stringForKey:@"NBUserPassword"];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - Helpers

+ (BOOL)shouldUseHTTPStubbing
{
    static BOOL shouldUse;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *launchArguments = [NSUserDefaults standardUserDefaults];
        shouldUse = [launchArguments objectForKey:@"NBShouldUseHTTPStubbing"] != nil;
    });
    return shouldUse;
}

- (BOOL)shouldUseHTTPStubbing
{
    return [self.class shouldUseHTTPStubbing];
}

- (BOOL)shouldOnlyUseTestToken
{
    return !self.userPassword;
}

- (LSStubResponseDSL *)stubRequestWithMethod:(NSString *)method
                                       path:(NSString *)path
                                 identifier:(NSUInteger)identifier
                                 parameters:(NSDictionary *)parameters
{
    NSURLComponents *components = [NSURLComponents componentsWithURL:self.baseURL resolvingAgainstBaseURL:NO];
    components.path = [NSString stringWithFormat:@"/api/%@/%@", self.client.apiVersion, path];
    BOOL hasIdentifier = identifier != NSNotFound;
    if (hasIdentifier) {
        components.path = [components.path stringByAppendingString:[NSString stringWithFormat:@"/%lu", identifier]];
    }
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    mutableParameters[@"access_token"] = self.client.apiKey;
    components.query = [mutableParameters nb_queryStringWithEncoding:NSASCIIStringEncoding
                                         skipPercentEncodingPairKeys:[NSSet setWithObject:@"email"]
                                          charactersToLeaveUnescaped:nil];
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    headers[@"Accept"] = @"application/json";
    if ([method isEqual:@"POST"] || [method isEqual:@"PUT"]) {
        headers[@"Content-Type"] = @"application/json";
    }
    NSString *fileName = [NSString stringWithFormat:@"%@%@_%@",
                          [path stringByReplacingOccurrencesOfString:@"/" withString:@"_"],
                          (hasIdentifier ? @"_id" : @""),
                          method.lowercaseString];
    NSData *data = [NSData dataWithContentsOfFile:
                    [[NSBundle bundleForClass:self.class] pathForResource:fileName ofType:@"txt"]];
    NSLog(@"STUB: %@", components.URL.absoluteString);
    return stubRequest(method, components.URL.absoluteString).withHeaders(headers).andReturnRawResponse(data);
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
