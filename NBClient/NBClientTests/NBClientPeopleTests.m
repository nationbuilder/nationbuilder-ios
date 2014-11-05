//
//  NBClientPeopleTests.m
//  NBClient
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBTestCase.h"

#import "FoundationAdditions.h"

#import "NBClient.h"
#import "NBClient+People.h"
#import "NBPaginationInfo.h"

@interface NBClientPeopleTests : NBTestCase

- (void)assertPeopleArray:(NSArray *)array;
- (void)assertPersonDictionary:(NSDictionary *)dictionary;

@end

@implementation NBClientPeopleTests

- (void)setUp
{
    [super setUp];
    [self setUpSharedClient];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - Helpers

- (void)assertPeopleArray:(NSArray *)array
{
    XCTAssertNotNil(array,
                    @"Client should have fetched list of people.");
    for (NSDictionary *dictionary in array) {
        [self assertPersonDictionary:dictionary];
    }
}

- (void)assertPersonDictionary:(NSDictionary *)dictionary
{
    static NSArray *keys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keys = @[ @"email", @"id", @"first_name", @"last_name", @"support_level" ];
    });
    for (NSString *key in keys) {
        XCTAssertNotNil(dictionary[key],
                        @"Person dictionary should have value for %@", key);
    }
}

#pragma mark - Tests

- (void)testFetchPeople
{
    [self setUpAsync];
    NSDictionary *paginationParameters = @{ NBClientCurrentPageNumberKey: @1,
                                            NBClientNumberOfItemsPerPageKey: @5 };
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"people" identifier:NSNotFound parameters:paginationParameters];
    }
    NBPaginationInfo *paginationInfo =
    [[NBPaginationInfo alloc] initWithDictionary:paginationParameters];
    NSURLSessionDataTask *task =
    [self.client
     fetchPeopleWithPaginationInfo:paginationInfo
     completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
         [self assertServiceError:error];
         [self assertPeopleArray:items];
         [self assertPaginationInfo:paginationInfo withPaginationParameters:paginationParameters];
         [self completeAsync];
    }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testFetchPeopleByParameters
{
    [self setUpAsync];
    NSDictionary *paginationParameters = @{ NBClientCurrentPageNumberKey: @1,
                                            NBClientNumberOfItemsPerPageKey: @5 };
    NSDictionary *parameters = @{ @"state": @"CA" };
    if (self.shouldUseHTTPStubbing) {
        NSMutableDictionary *mutableParameters = paginationParameters.mutableCopy;
        [mutableParameters addEntriesFromDictionary:parameters];
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"people/search" identifier:NSNotFound parameters:mutableParameters];
    }
    NBPaginationInfo *paginationInfo =
    [[NBPaginationInfo alloc] initWithDictionary:paginationParameters];
    NSURLSessionDataTask *task =
    [self.client
     fetchPeopleByParameters: parameters
     withPaginationInfo:paginationInfo
     completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
         [self assertServiceError:error];
         [self assertPeopleArray:items];
         [self assertPaginationInfo:paginationInfo withPaginationParameters:paginationParameters];
         [self completeAsync];
     }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testFetchPersonByIdentifier
{
    [self setUpAsync];
    NSUInteger identifier = self.userIdentifier;
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"people" identifier:identifier parameters:nil];
    }
    NSURLSessionDataTask *task =
    [self.client
     fetchPersonByIdentifier:identifier
     withCompletionHandler:^(NSDictionary *item, NSError *error) {
        [self assertServiceError:error];
        [self assertPersonDictionary:item];
        [self completeAsync];
    }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testFetchPersonByParameters
{
    [self setUpAsync];
    NSDictionary *parameters = @{ @"email" : self.userEmailAddress };
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"people/match" identifier:NSNotFound parameters:parameters];
    }
    NSURLSessionDataTask *task =
    [self.client
     fetchPersonByParameters: parameters
     withCompletionHandler:^(NSDictionary *item, NSError *error) {
         [self assertServiceError:error];
         [self assertPersonDictionary:item];
         [self completeAsync];
     }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testFetchPersonByClientParameters
{
    [self setUpAsync];
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"people/me" identifier:NSNotFound parameters:nil];
    }
    NSURLSessionDataTask *task =
    [self.client
     fetchPersonForClientUserWithCompletionHandler:^(NSDictionary *item, NSError *error) {
         [self assertServiceError:error];
         [self assertPersonDictionary:item];
         [self completeAsync];
     }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testCreatePerson
{
    [self setUpAsync];
    NSDictionary *parameters = @{ @"first_name": @"Foo", @"last_name": @"Bar" };
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"POST" path:@"people" identifier:NSNotFound parameters:nil];
    }
    NSURLSessionDataTask *task =
    [self.client
     createPersonWithParameters:parameters
     completionHandler:^(NSDictionary *item, NSError *error) {
         [self assertServiceError:error];
         [self assertPersonDictionary:item];
         XCTAssertTrue([item nb_containsDictionary:parameters],
                       @"Person dictionary should be populated by parameters.");
         if (self.shouldUseHTTPStubbing) {
             [self completeAsync];
         } else {
             [self.client deletePersonByIdentifier:[item[@"id"] unsignedIntegerValue]
                             withCompletionHandler:^(NSDictionary *item, NSError *error) { [self completeAsync]; }];
         }
     }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testSavePerson
{
    [self setUpAsync];
    NSUInteger identifier = self.userIdentifier;
    NSDictionary *parameters = @{ @"demo": @"B" };
    void (^testSave)(NSDictionary *, NSError *) = ^(NSDictionary *item, NSError *error) {
        NSURLSessionDataTask *task =
        [self.client
         savePersonByIdentifier:identifier
         withParameters:parameters
         completionHandler:^(NSDictionary *item, NSError *error) {
             [self assertServiceError:error];
             [self assertPersonDictionary:item];
             XCTAssertTrue([item nb_containsDictionary:parameters],
                           @"Person dictionary should be populated by parameters.");
             if (self.shouldUseHTTPStubbing) {
                 [self completeAsync];
             } else {
                 [self.client savePersonByIdentifier:identifier withParameters:@{ @"demo": @"W" }
                                   completionHandler:^(NSDictionary *item, NSError *error) { [self completeAsync]; }];
             }
         }];
        [self assertSessionDataTask:task];
    };
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"PUT" path:@"people" identifier:identifier parameters:nil];
        testSave(nil, nil);
    } else {
        [self.client fetchPersonByIdentifier:self.userIdentifier withCompletionHandler:testSave];
    }
    [self tearDownAsync];
}

- (void)testDeletePerson
{
    [self setUpAsync];
    NSUInteger identifier = 701;
    void (^testDelete)(NSDictionary *, NSError *) = ^(NSDictionary *item, NSError *error) {
        NSURLSessionDataTask *task =
        [self.client
         deletePersonByIdentifier:(!item ? identifier : [item[@"id"] unsignedIntegerValue])
         withCompletionHandler:^(NSDictionary *item, NSError *error) {
             [self assertServiceError:error];
             XCTAssertNil(item,
                          @"Person dictionary should not exist.");
             [self completeAsync];
         }];
        [self assertSessionDataTask:task];
    };
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"DELETE" path:@"people" identifier:identifier parameters:nil];
        testDelete(nil, nil);
    } else {
        NSDictionary *parameters = @{ @"first_name": @"Foo", @"last_name": @"Bar" };
        [self.client createPersonWithParameters:parameters completionHandler:testDelete];
    }
    [self tearDownAsync];
}

@end
