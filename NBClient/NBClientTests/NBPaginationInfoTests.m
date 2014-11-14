//
//  NBPaginationInfoTests.m
//  NBClient
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NBTestCase.h"

#import "NBPaginationInfo.h"

@interface NBPaginationInfoTests : NBTestCase

@property (nonatomic) NSDictionary *dictionary;
@property (nonatomic) NBPaginationInfo *paginationInfo;

@end

@implementation NBPaginationInfoTests

- (void)setUp
{
    [super setUp];
    self.dictionary = @{ NBClientCurrentPageNumberKey: @2,
                         NBClientNumberOfTotalPagesKey: @10,
                         NBClientNumberOfItemsPerPageKey: @10,
                         NBClientNumberOfTotalItemsKey: @100 };
    self.paginationInfo = [[NBPaginationInfo alloc] init];
    self.paginationInfo.currentPageNumber = 2;
    self.paginationInfo.numberOfTotalPages = 10;
    self.paginationInfo.numberOfItemsPerPage = 10;
    self.paginationInfo.numberOfTotalItems = 100;
    self.paginationInfo.numberOfTotalAvailableItems = 15;
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

- (void)testCurrentPageNumberConstraints
{
    self.paginationInfo.currentPageNumber = 0;
    XCTAssertEqual(self.paginationInfo.currentPageNumber, 1,
                   @"Current page number should not be less than 1.");
}

- (void)testIndexOfFirstItemAtPage
{
    XCTAssertEqual([self.paginationInfo indexOfFirstItemAtPage:2], 10,
                   @"First page item index should be properly calculated.");
}

- (void)testNumberOfItemsAtPage
{
    XCTAssertEqual([self.paginationInfo numberOfItemsAtPage:1], 10,
                   @"Non-last page item count should be properly calculated.");
    XCTAssertEqual([self.paginationInfo numberOfItemsAtPage:2], 5,
                   @"Last page item count should be properly calculated.");
}

@end
