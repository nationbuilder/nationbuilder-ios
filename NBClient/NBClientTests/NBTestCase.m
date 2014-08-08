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

@property (nonatomic, strong, readwrite) NBClient *client;

@end

@implementation NBTestCase

- (void)setUp
{
    [super setUp];
    // Provide default config for test cases.
    NSUserDefaults *launchArguments = [NSUserDefaults standardUserDefaults];
    self.nationName = [launchArguments stringForKey:@"NBNationName"];
    NSAssert(self.nationName, @"Missing environment arguments for tests.");
    self.baseURL = [NSURL URLWithString:
                    [NSString stringWithFormat:[launchArguments stringForKey:@"NBBaseURLFormat"], self.nationName]];
    self.apiKey = [launchArguments stringForKey:@"NBTestToken"];
    self.clientIdentifier = [launchArguments stringForKey:@"NBClientIdentifier"];
    self.clientSecret = [launchArguments stringForKey:@"NBClientSecret"];
    self.userEmailAddress = [launchArguments stringForKey:@"NBUserEmailAddress"];
    self.userIdentifier = [launchArguments integerForKey:@"NBUserIdentifier"];
    self.userPassword = [launchArguments stringForKey:@"NBUserPassword"];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - Helpers

- (void)setUpSharedClient
{
    // We need to use the shared session because we need to be in an application
    // for an app-specific cache.
    NBAuthenticator *authenticator = [[NBAuthenticator alloc] initWithBaseURL:self.baseURL
                                                             clientIdentifier:self.clientIdentifier
                                                                 clientSecret:self.clientSecret];
    __block NSString *apiKey;
    NSURLSessionDataTask *task = [authenticator
                                  authenticateWithUserName:self.userEmailAddress
                                  password:self.userPassword
                                  completionHandler:^(NBAuthenticationCredential *credential, NSError *error) {
                                      apiKey = credential.accessToken;
                                  }];
    NSAssert(!task, @"Test case requires saved authentication credential. Re-authenticating should not happen.");
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
}

- (void)completeAsync
{
    self.didCallBack = YES;
}

@end
