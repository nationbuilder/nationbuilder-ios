//
//  NBClientListsTests.m
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBTestCase.h"

#import "FoundationAdditions.h"

#import "NBClient.h"
#import "NBClient+Lists.h"
#import "NBPaginationInfo.h"

@interface NBClientListsTests : NBTestCase

@property (nonatomic) NSUInteger listIdentifier;
@property (nonatomic) NSDictionary *paginationParameters;
@property (nonatomic) NSArray *peopleIdentifiers;

- (void)assertListsArray:(NSArray *)array;
- (void)assertListDictionary:(NSDictionary *)dictionary;

@end

@implementation NBClientListsTests

- (void)setUp
{
    [super setUp];
    [self setUpSharedClient];
    self.listIdentifier = 3;
    self.paginationParameters = @{ NBClientPaginationLimitKey: @5, NBClientPaginationTokenOptInKey: @1 };
    self.peopleIdentifiers = @[ @(self.userIdentifier) ];
}

#pragma mark - Helpers

- (void)assertListsArray:(NSArray *)array
{
    XCTAssertNotNil(array, @"Client should have received list of lists.");
    for (NSDictionary *dictionary in array) { [self assertListDictionary:dictionary]; }
}

- (void)assertListDictionary:(NSDictionary *)dictionary
{
    static NSArray *keys; static dispatch_once_t onceToken; dispatch_once(&onceToken, ^{
        keys = @[ @"id", @"name", @"slug", @"author_id", @"count" ];
    });
    return XCTAssertTrue([dictionary nb_hasKeys:keys], "List has correct attributes.");
}

#pragma mark - Tests

- (void)testFetchLists
{
    [self setUpAsync];
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"lists" queryParameters:self.paginationParameters];
    }
    NSURLSessionDataTask *task =
    [self.client
     fetchListsWithPaginationInfo:[[NBPaginationInfo alloc] initWithDictionary:self.paginationParameters legacy:NO]
     completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
        [self assertServiceError:error];
        [self assertListsArray:items];
        [self assertPaginationInfo:paginationInfo withPaginationParameters:self.paginationParameters];
        [self completeAsync];
    }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testFetchListPeople
{
    if (!self.shouldUseHTTPStubbing) { return; }
    [self setUpAsync];
    [self stubRequestUsingFileDataWithMethod:@"GET" pathFormat:@"lists/:id/people" pathVariables:@{ @"id": @(self.listIdentifier) } queryParameters:self.paginationParameters];
    NSURLSessionDataTask *task =
    [self.client
     fetchListPeopleByIdentifier:self.listIdentifier
     withPaginationInfo:[[NBPaginationInfo alloc] initWithDictionary:self.paginationParameters legacy:NO]
     completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
        [self assertServiceError:error];
        [self assertPeopleArray:items];
        [self assertPaginationInfo:paginationInfo withPaginationParameters:self.paginationParameters];
        [self completeAsync];
    }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testCreatePeopleListings
{
    if (!self.shouldUseHTTPStubbing) { return; }
    [self setUpAsync];
    [self stubRequestUsingFileDataWithMethod:@"POST" pathFormat:@"lists/:id/people" pathVariables:@{ @"id": @(self.listIdentifier) } queryParameters:nil];
    NSURLSessionDataTask *task =
    [self.client createPeopleListingsByIdentifier:self.listIdentifier withPeopleIdentifiers:self.peopleIdentifiers completionHandler:^(NSDictionary *item, NSError *error) {
        [self assertServiceError:error];
        XCTAssertNil(item, @"There should be no response.");
        [self completeAsync];
    }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testDeletePeopleListings
{
    if (!self.shouldUseHTTPStubbing) { return; }
    [self setUpAsync];
    [self stubRequestUsingFileDataWithMethod:@"DELETE" pathFormat:@"lists/:id/people" pathVariables:@{ @"id": @(self.listIdentifier) } queryParameters:nil];
    NSURLSessionDataTask *task =
    [self.client deletePeopleListingsByIdentifier:self.listIdentifier withPeopleIdentifiers:self.peopleIdentifiers completionHandler:^(NSDictionary *item, NSError *error) {
        [self assertServiceError:error];
        XCTAssertNil(item, @"There should be no response.");
        [self completeAsync];
    }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

@end
