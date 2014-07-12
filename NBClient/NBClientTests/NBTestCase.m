//
//  NBTestCase.m
//  NBClient
//
//  Created by Peng Wang on 7/11/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBTestCase.h"

@interface NBTestCase ()

@property (nonatomic) BOOL didCallBack;

@end

@implementation NBTestCase

- (void)setUp
{
    [super setUp];
    // Provide default config for test cases.
    self.nationName = @"abeforprez";
    self.baseURL = [NSURL URLWithString:
                    [NSString stringWithFormat:@"http://%@.nbuild.dev", self.nationName]];
    self.apiKey = @"9a888b2e71393a3c6b327b32366754287c813714ae51e0f7938a7ee608a064f1";
    self.clientIdentifier = @"ca76d8aa658b4a0af4aba5599f4443bed47895025799a63f9f75669ebc67dd9d";
    self.clientSecret = @"6c63db2494d69f715157075d1794074a522990a97dc1324910d605c89859b4a8";
    self.userEmailAddress = @"help@nationbuilder.com";
    self.userPassword = @"password";
}

- (void)tearDown
{
    [super tearDown];
}

# pragma mark - Async API

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
