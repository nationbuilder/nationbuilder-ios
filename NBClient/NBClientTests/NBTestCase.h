//
//  NBTestCase.h
//  NBClient
//
//  Created by Peng Wang on 7/11/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <XCTest/XCTest.h>

@class NBPaginationInfo;

@interface NBTestCase : XCTestCase

@property (nonatomic, strong) NSString *nationName;
@property (nonatomic, strong) NSURL *baseURL;

@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, strong) NSString *clientIdentifier;
@property (nonatomic, strong) NSString *clientSecret;
@property (nonatomic, strong) NSString *userEmailAddress;
@property (nonatomic) NSUInteger userIdentifier;
@property (nonatomic, strong) NSString *userPassword;

- (void)assertPaginationInfo:(NBPaginationInfo *)paginationInfo
    withPaginationParameters:(NSDictionary *)paginationParameters;
- (void)assertServiceError:(NSError *)error;
- (void)assertSessionDataTask:(NSURLSessionDataTask *)task;

// NOTE: This async test API should be removed whenever we start running tests on iOS 8.

@property (nonatomic) NSTimeInterval asyncTimeoutInterval;

- (void)setUpAsync;
- (void)tearDownAsync;
- (void)completeAsync;

@end
