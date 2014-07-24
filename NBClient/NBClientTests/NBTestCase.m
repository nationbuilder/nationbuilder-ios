//
//  NBTestCase.m
//  NBClient
//
//  Created by Peng Wang on 7/11/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBTestCase.h"

#import "FoundationAdditions.h"
#import "NBClient.h"
#import "NBPaginationInfo.h"

@interface NBTestCase ()

@property (nonatomic) BOOL didCallBack;

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
    self.apiKey = [launchArguments stringForKey:@"NBClientAPIKey"];
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

- (void)assertPaginationInfo:(NBPaginationInfo *)paginationInfo
    withPaginationParameters:(NSDictionary *)paginationParameters
{
    XCTAssertTrue((@(paginationInfo.currentPageNumber) &&
                   paginationInfo.currentPageNumber == [paginationParameters[NBClientCurrentPageNumberKey] unsignedIntegerValue]),
                  @"Pagination info should be properly populated.");
    XCTAssertNotNil(@(paginationInfo.numberOfTotalPages),
                    @"Pagination info should be properly populated.");
    XCTAssertTrue((@(paginationInfo.numberOfItemsPerPage) &&
                   paginationInfo.numberOfItemsPerPage == [paginationParameters[NBClientNumberOfItemsPerPageKey] unsignedIntegerValue]),
                  @"Pagination info should be properly populated.");
    XCTAssertNotNil(@(paginationInfo.numberOfTotalItems),
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
    NSLog(@"REQUEST: %@", task.currentRequest.nb_debugDescription);
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
