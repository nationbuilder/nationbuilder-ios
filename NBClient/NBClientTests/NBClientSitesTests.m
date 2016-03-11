//
//  NBClientSitesTests.m
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBTestCase.h"

#import "FoundationAdditions.h"

#import "NBClient.h"
#import "NBClient+Sites.h"
#import "NBPaginationInfo.h"

@interface NBClientSitesTests : NBTestCase

@property (nonatomic) NSDictionary *paginationParameters;

- (void)assertSitesArray:(NSArray *)array;
- (void)assertSiteDictionary:(NSDictionary *)dictionary;

@end

@implementation NBClientSitesTests

- (void)setUp
{
    [super setUp];
    [self setUpSharedClient];
    self.paginationParameters = @{ NBClientPaginationLimitKey: @5, NBClientPaginationTokenOptInKey: @1 };
}

#pragma mark - Helpers

- (void)assertSitesArray:(NSArray *)array
{
    XCTAssertNotNil(array, @"Client should have received list of sites.");
    for (NSDictionary *dictionary in array) { [self assertSiteDictionary:dictionary]; }
}

- (void)assertSiteDictionary:(NSDictionary *)dictionary
{
    static NSArray *keys; static dispatch_once_t onceToken; dispatch_once(&onceToken, ^{
        keys = @[ @"id", @"name", @"slug", @"domain" ];
    });
    return XCTAssertTrue([dictionary nb_hasKeys:keys], "Site has correct attributes.");
}

#pragma mark - Tests

- (void)testFetchSites
{
    [self setUpAsync];
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"sites" queryParameters:self.paginationParameters];
    }
    NBPaginationInfo *requestPaginationInfo = [[NBPaginationInfo alloc] initWithDictionary:self.paginationParameters legacy:NO];
    NSURLSessionDataTask *task =
    [self.client fetchSitesWithPaginationInfo:requestPaginationInfo completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
        [self assertServiceError:error];
        [self assertSitesArray:items];
        [self assertPaginationInfo:paginationInfo withPaginationParameters:self.paginationParameters];
        [self completeAsync];
    }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

@end

