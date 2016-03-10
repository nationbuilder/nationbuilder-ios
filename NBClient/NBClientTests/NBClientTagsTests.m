//
//  NBClientTagsTests.m
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBTestCase.h"

#import "FoundationAdditions.h"

#import "NBClient.h"
#import "NBClient+Tags.h"
#import "NBPaginationInfo.h"

@interface NBClientTagsTests : NBTestCase

@property (nonatomic) NSString *tagName;
@property (nonatomic) NSDictionary *paginationParameters;

@end

@implementation NBClientTagsTests

- (void)setUp
{
    [super setUp];
    [self setUpSharedClient];
    self.tagName = @"ios";
    self.paginationParameters = @{ NBClientPaginationLimitKey: @5, NBClientPaginationTokenOptInKey: @1 };
}

#pragma mark - Helpers

- (void)assertTagsArray:(NSArray *)array
{
    XCTAssertNotNil(array, @"Client should have received list of tags.");
    for (NSDictionary *dictionary in array) { [self assertTagDictionary:dictionary]; }
}

- (void)assertTagDictionary:(NSDictionary *)dictionary
{
    static NSArray *keys; static dispatch_once_t onceToken; dispatch_once(&onceToken, ^{ keys = @[ @"name" ]; });
    return XCTAssertTrue([dictionary nb_hasKeys:keys], "List has correct attributes.");
}

- (void)assertPeopleArray:(NSArray *)array
{
    XCTAssertNotNil(array, @"Client should have received list of people.");
    for (NSDictionary *dictionary in array) { [self assertPersonDictionary:dictionary]; }
}

- (void)assertPersonDictionary:(NSDictionary *)dictionary
{
    static NSArray *keys; static dispatch_once_t onceToken; dispatch_once(&onceToken, ^{
        keys = @[ @"email", @"id", @"first_name", @"last_name", @"support_level" ];
    });
    return XCTAssertTrue([dictionary nb_hasKeys:keys], "Person has correct attributes.");
}

#pragma mark - Tests

- (void)testFetchTags
{
    [self setUpAsync];
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"tags" queryParameters:self.paginationParameters];
    }
    NBPaginationInfo *requestPaginationInfo = [[NBPaginationInfo alloc] initWithDictionary:self.paginationParameters legacy:NO];
    NSURLSessionDataTask *task =
    [self.client fetchTagsWithPaginationInfo:requestPaginationInfo completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
        [self assertServiceError:error];
        [self assertTagsArray:items];
        [self assertPaginationInfo:paginationInfo withPaginationParameters:self.paginationParameters];
        [self completeAsync];
    }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testFetchTagPeople
{
    [self setUpAsync];
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" pathFormat:@"tags/:tag/people" pathVariables:@{ @"tag": self.tagName } queryParameters:self.paginationParameters];
    }
    NBPaginationInfo *requestPaginationInfo = [[NBPaginationInfo alloc] initWithDictionary:self.paginationParameters legacy:NO];
    NSURLSessionDataTask *task =
    [self.client fetchTagPeopleByName:self.tagName withPaginationInfo:requestPaginationInfo completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
        [self assertServiceError:error];
        [self assertPeopleArray:items];
        [self assertPaginationInfo:paginationInfo withPaginationParameters:self.paginationParameters];
        [self completeAsync];
    }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

@end
