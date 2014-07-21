//
//  NBPaginationInfoTests.m
//  NBClient
//
//  Created by Peng Wang on 7/21/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NBTestCase.h"

#import "NBPaginationInfo.h"

@interface NBPaginationInfoTests : NBTestCase

@property (nonatomic, strong) NSDictionary *dictionary;
@property (nonatomic, strong) NBPaginationInfo *paginationInfo;

@end

@implementation NBPaginationInfoTests

- (void)setUp
{
    [super setUp];
    self.dictionary = @{ NBClientCurrentPageNumberKey: @1,
                         NBClientNumberOfTotalPagesKey: @2,
                         NBClientNumberOfItemsPerPageKey: @10,
                         NBClientNumberOfTotalItemsKey: @15 };
    self.paginationInfo = [[NBPaginationInfo alloc] init];
    self.paginationInfo.currentPageNumber = 1;
    self.paginationInfo.numberOfTotalPages = 2;
    self.paginationInfo.numberOfItemsPerPage = 10;
    self.paginationInfo.numberOfTotalItems = 15;
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testInitializingWithDictionary
{
    NBPaginationInfo *paginationInfo = [[NBPaginationInfo alloc] initWithDictionary:self.dictionary];
    XCTAssertTrue([paginationInfo isEqualToDictionary:self.dictionary],
                  @"Pagination should properly init from dictionary.");
}

- (void)testGeneratingDictionary
{
    NSDictionary *dictionary = self.paginationInfo.dictionary;
    XCTAssertTrue([self.paginationInfo isEqualToDictionary:dictionary],
                  @"Pagination should properly generate dictionary.");
}

- (void)testCheckingEqualityWithDictionary
{
    XCTAssertTrue([self.paginationInfo isEqualToDictionary:self.dictionary],
                  @"Pagination should be equal to dictionary.");
}

@end
