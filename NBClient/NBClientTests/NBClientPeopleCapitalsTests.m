//
//  NBClientPeopleCapitalsTests.m
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import "NBTestCase.h"

#import "FoundationAdditions.h"

#import "NBClient.h"
#import "NBClient+People.h"
#import "NBPaginationInfo.h"

@interface NBClientPeopleCapitalsTests : NBTestCase

@property (nonatomic) NSUInteger amountInCents;
@property (nonatomic) NSString *userContent;

- (void)assertCapitalsArray:(NSArray *)array;
- (void)assertCapitalDictionary:(NSDictionary *)dictionary;

@end

@implementation NBClientPeopleCapitalsTests

- (void)setUp {
    [super setUp];
    [self setUpSharedClient];
    self.amountInCents = 100;
    self.userContent = @"test";
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - Helpers

- (void)assertCapitalsArray:(NSArray *)array
{
    XCTAssertNotNil(array, @"Client should have received list of capitals.");
    for (NSDictionary *dictionary in array) {
        [self assertCapitalDictionary:dictionary];
    }
}

- (void)assertCapitalDictionary:(NSDictionary *)dictionary
{
    NSArray *keys = [@[ @"id", @"person_id", @"author_id", @"type", @"amount_in_cents", @"created_at", @"content" ]
                     sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    XCTAssertEqualObjects([dictionary.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)], keys,
                          "Capital has correct attributes.");
}

#pragma mark - Tests

- (void)testFetchPersonCapitals
{
    [self setUpAsync];
    NSDictionary *paginationParameters = @{ NBClientPaginationLimitKey: @5, NBClientPaginationTokenOptInKey: @1 };
    NSUInteger personIdentifier = self.userIdentifier;
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" pathFormat:@"people/:id/capitals" pathVariables:@{ @"id": @(personIdentifier) } queryParameters:paginationParameters];
    }
    NBPaginationInfo *requestPaginationInfo = [[NBPaginationInfo alloc] initWithDictionary:paginationParameters legacy:NO];
    NSURLSessionDataTask *task =
    [self.client
     fetchPersonCapitalsByIdentifier:personIdentifier
     withPaginationInfo:requestPaginationInfo
     completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
         [self assertServiceError:error];
         [self assertCapitalsArray:items];
         [self completeAsync];
     }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];}

- (void)testCreatePersonCapital
{
    [self setUpAsync];
    NSDictionary *capitalInfo = @{ NBClientCapitalAmountInCentsKey: @(self.amountInCents),
                                   NBClientCapitalUserContentKey: self.userContent };
    NSUInteger personIdentifier = self.userIdentifier;
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"POST" pathFormat:@"people/:id/capitals" pathVariables:@{ @"id": @(personIdentifier) } queryParameters:nil];
    }
    void (^undoTestChanges)(NSUInteger) = ^(NSUInteger capitalIdentifier) {
        [self.client deletePersonCapitalByPersonIdentifier:personIdentifier capitalIdentifier:capitalIdentifier
                                     withCompletionHandler:^(NSDictionary *item, NSError *error) { [self completeAsync]; }];
    };
    NSURLSessionDataTask *task =
    [self.client
     createPersonCapitalByIdentifier:personIdentifier
     withCapitalInfo:capitalInfo
     completionHandler:^(NSDictionary *item, NSError *error) {
         [self assertServiceError:error];
         [self assertCapitalDictionary:item];
         NSMutableDictionary *mutatedCapitalInfo = capitalInfo.mutableCopy;
         mutatedCapitalInfo[NBClientCapitalUserContentKey] = @{ @"note": self.userContent };
         XCTAssertTrue([item nb_containsDictionary:mutatedCapitalInfo],
                       @"Capital dictionary should be populated by parameters.");
         if (self.shouldUseHTTPStubbing) {
             [self completeAsync];
         } else {
             undoTestChanges([item[@"id"] unsignedIntegerValue]);
         }
     }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testDeletePersonCapital
{
    [self setUpAsync];
    NSUInteger personIdentifier = self.userIdentifier;
    NBClientResourceItemCompletionHandler testDelete = ^(NSDictionary *item, NSError *error) {
        NSURLSessionDataTask *task =
        [self.client
         deletePersonCapitalByPersonIdentifier:personIdentifier
         capitalIdentifier:[item[@"id"] unsignedIntegerValue]
         withCompletionHandler:^(NSDictionary *deletedItem, NSError *deleteError) {
             [self assertServiceError:deleteError];
             XCTAssertNil(deletedItem, @"Capital should not exist.");
             [self completeAsync];
         }];
        [self assertSessionDataTask:task];
    };
    if (self.shouldUseHTTPStubbing) {
        NSUInteger capitalIdentifier = 514;
        [self stubRequestUsingFileDataWithMethod:@"DELETE" pathFormat:@"people/:person_id/capitals/:capital_id"
                                   pathVariables:@{ @"person_id": @(personIdentifier), @"capital_id": @(capitalIdentifier) } queryParameters:nil];
        testDelete(@{ @"id": @(capitalIdentifier) }, nil);
    } else {
        [self completeAsync]; // FIXME
        [self.client createPersonCapitalByIdentifier:personIdentifier
                                     withCapitalInfo:@{ NBClientCapitalAmountInCentsKey: @(self.amountInCents),
                                                        NBClientCapitalUserContentKey: self.userContent }
                                   completionHandler:testDelete];
    }
    [self tearDownAsync];
}

@end
