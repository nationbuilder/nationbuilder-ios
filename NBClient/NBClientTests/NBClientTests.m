//
//  NBClientTests.m
//  NBClientTests
//
//  Created by Peng Wang on 7/8/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "Main.h"

@interface NBClientTests : XCTestCase

@property (nonatomic, strong) NSString *nationName;
@property (nonatomic, strong) NSString *apiKey;

@end

@implementation NBClientTests

- (void)setUp
{
    [super setUp];
    self.nationName = @"abeforprez";
    // FIXME: This is a dev environment key.
    self.apiKey = @"9a888b2e71393a3c6b327b32366754287c813714ae51e0f7938a7ee608a064f1";
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testDefaultInitialization
{
    NBClient *client = [[NBClient alloc] initWithNationName:self.nationName
                                                     apiKey:self.apiKey
                                           customURLSession:nil customURLSessionConfiguration:nil];
    XCTAssertNotNil(client.urlSession,
                    @"Client should have default session.");
    XCTAssertNotNil(client.sessionConfiguration,
                    @"Client should have default session configuration.");
    XCTAssertNotNil(client.sessionConfiguration.URLCache,
                    @"Client should have default session cache.");
}

@end
