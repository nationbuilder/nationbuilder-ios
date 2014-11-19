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

@property (nonatomic, copy) NSDictionary *dictionary;
@property (nonatomic) NBPaginationInfo *paginationInfo;

@property (nonatomic, copy) NSDictionary *legacyDictionary;
@property (nonatomic) NBPaginationInfo *legacyPaginationInfo;

@end

@implementation NBPaginationInfoTests

- (void)setUp
{
    [super setUp];
    NSString *urlString = @"/api/v1/resource?__nonce=somehash&__token=somehash&limit=10";
    // Given: dictionary and pagination info contain same values.
    self.dictionary = @{ NBClientPaginationLimitKey: @10,
                         NBClientPaginationNextLinkKey: urlString,
                         NBClientPaginationPreviousLinkKey: urlString };
    self.paginationInfo = [[NBPaginationInfo alloc] initWithDictionary:nil legacy:NO];
    self.paginationInfo.numberOfItemsPerPage = 10;
    self.paginationInfo.nextPageURLString = urlString;
    self.paginationInfo.previousPageURLString = urlString;
    // Legacy.
    self.legacyDictionary = @{ NBClientCurrentPageNumberKey: @2,
                               NBClientNumberOfTotalPagesKey: @10,
                               NBClientNumberOfItemsPerPageKey: @10,
                               NBClientNumberOfTotalItemsKey: @100 };
    self.legacyPaginationInfo = [[NBPaginationInfo alloc] initWithDictionary:nil legacy:YES];
    self.legacyPaginationInfo.currentPageNumber = 2;
    self.legacyPaginationInfo.numberOfTotalPages = 10;
    self.legacyPaginationInfo.numberOfItemsPerPage = 10;
    self.legacyPaginationInfo.numberOfTotalItems = 100;
    self.legacyPaginationInfo.numberOfTotalAvailableItems = 15;
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testInitializingWithDictionary
{
    NBPaginationInfo *paginationInfo = [[NBPaginationInfo alloc] initWithDictionary:self.dictionary legacy:NO];
    XCTAssertTrue([paginationInfo isEqualToDictionary:self.dictionary],
                  @"Pagination should properly init from dictionary.");
}

- (void)testGeneratingDictionary
{
    NSDictionary *dictionary = [self.paginationInfo dictionary];
    XCTAssertTrue([self.paginationInfo isEqualToDictionary:dictionary],
                  @"Pagination should properly generate dictionary.");
}

- (void)testCheckingEqualityWithDictionary
{
    XCTAssertTrue([self.paginationInfo isEqualToDictionary:self.dictionary],
                  @"Pagination should be equal to dictionary.");
}

#pragma mark - Legacy

- (void)testInitializingWithLegacyDictionary
{
    NBPaginationInfo *paginationInfo = [[NBPaginationInfo alloc] initWithDictionary:self.legacyDictionary legacy:YES];
    XCTAssertTrue([paginationInfo isEqualToDictionary:self.legacyDictionary],
                  @"Pagination should properly init from dictionary.");
}

- (void)testGeneratingLegacyDictionary
{
    NSDictionary *dictionary = [self.legacyPaginationInfo dictionary];
    XCTAssertTrue([self.legacyPaginationInfo isEqualToDictionary:dictionary],
                  @"Pagination should properly generate dictionary.");
}

- (void)testCheckingEqualityWithLegacyDictionary
{
    XCTAssertTrue([self.legacyPaginationInfo isEqualToDictionary:self.legacyDictionary],
                  @"Pagination should be equal to dictionary.");
}

- (void)testCurrentPageNumberConstraints
{
    self.legacyPaginationInfo.currentPageNumber = 0;
    XCTAssertEqual(self.legacyPaginationInfo.currentPageNumber, (NSUInteger)1,
                   @"Current page number should not be less than 1.");
}

- (void)testIndexOfFirstItemAtPage
{
    XCTAssertEqual([self.legacyPaginationInfo indexOfFirstItemAtPage:2], (NSUInteger)10,
                   @"First page item index should be properly calculated.");
}

- (void)testNumberOfItemsAtPage
{
    XCTAssertEqual([self.legacyPaginationInfo numberOfItemsAtPage:1], (NSUInteger)10,
                   @"Non-last page item count should be properly calculated.");
    XCTAssertEqual([self.legacyPaginationInfo numberOfItemsAtPage:2], (NSUInteger)5,
                   @"Last page item count should be properly calculated.");
}

@end
