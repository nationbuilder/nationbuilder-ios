//
//  NBClientPeopleCapitalsTests.m
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
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

- (void)setUp
{
    [super setUp];
    [self setUpSharedClient];
    self.amountInCents = 100;
    self.userContent = @"test";
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - Helpers

- (void)assertCapitalsArray:(NSArray *)array
{
    XCTAssertNotNil(array, @"Client should have received list of capitals.");
    for (NSDictionary *dictionary in array) { [self assertCapitalDictionary:dictionary]; }
}

- (void)assertCapitalDictionary:(NSDictionary *)dictionary
{
    static NSArray *keys; static dispatch_once_t onceToken; dispatch_once(&onceToken, ^{
        keys = @[ @"id", @"person_id", @"author_id", @"type", @"amount_in_cents", @"created_at", @"content" ];
    });
    return XCTAssertTrue([dictionary nb_hasKeys:keys], "Capital has correct attributes.");
}

#pragma mark - Tests

- (void)testFetchPersonCapitals
{
    [self setUpAsync];
    NSDictionary *paginationParameters = @{ NBClientPaginationLimitKey: @5, NBClientPaginationTokenOptInKey: @1 };
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" pathFormat:@"people/:id/capitals" pathVariables:@{ @"id": @(self.userIdentifier) } queryParameters:paginationParameters];
    }
    NSURLSessionDataTask *task =
    [self.client
     fetchPersonCapitalsByIdentifier:self.userIdentifier
     withPaginationInfo:[[NBPaginationInfo alloc] initWithDictionary:paginationParameters legacy:NO]
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
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"POST" pathFormat:@"people/:id/capitals" pathVariables:@{ @"id": @(self.supporterIdentifier) } queryParameters:nil];
    }
    NSURLSessionDataTask *task =
    [self.client
     createPersonCapitalByIdentifier:self.supporterIdentifier
     withCapitalInfo:@{ NBClientCapitalAmountInCentsKey: @(self.amountInCents), NBClientCapitalUserContentKey: self.userContent }
     completionHandler:^(NSDictionary *item, NSError *error) {
         [self assertServiceError:error];
         [self assertCapitalDictionary:item];
         [self completeAsync];
     }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testDeletePersonCapital
{
    [self setUpAsync];
    NBClientResourceItemCompletionHandler testDelete = ^(NSDictionary *item, NSError *error) {
        NSURLSessionDataTask *task =
        [self.client
         deletePersonCapitalByPersonIdentifier:self.supporterIdentifier
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
                                   pathVariables:@{ @"person_id": @(self.supporterIdentifier), @"capital_id": @(capitalIdentifier) } queryParameters:nil];
        testDelete(@{ @"id": @(capitalIdentifier) }, nil);
    } else {
        [self.client createPersonCapitalByIdentifier:self.supporterIdentifier
                                     withCapitalInfo:@{ NBClientCapitalAmountInCentsKey: @(self.amountInCents),
                                                        NBClientCapitalUserContentKey: self.userContent }
                                   completionHandler:testDelete];
    }
    [self tearDownAsync];
}

@end
