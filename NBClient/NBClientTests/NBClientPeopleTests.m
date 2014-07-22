//
//  NBClientPeopleTests.m
//  NBClient
//
//  Created by Peng Wang on 7/16/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBTestCase.h"

#import "Main.h"

@interface NBClientPeopleTests : NBTestCase

@property (strong, nonatomic) NBClient *client;

- (void)assertPeopleArray:(NSArray *)array;
- (void)assertPersonDictionary:(NSDictionary *)dictionary;
- (void)assertServiceError:(NSError *)error;
- (void)assertSessionDataTask:(NSURLSessionDataTask *)task;

@end

@implementation NBClientPeopleTests

- (void)setUp
{
    [super setUp];
    // We need to use the shared session because we need to be in an application
    // for an app-specific cache.
    self.client = [[NBClient alloc] initWithNationName:self.nationName
                                                apiKey:self.apiKey
                                      customURLSession:[NSURLSession sharedSession]
                         customURLSessionConfiguration:nil];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - Assertion Macros

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

- (void)assertPaginationInfo:(NBPaginationInfo *)paginationInfo
    withPaginationParameters:(NSDictionary *)paginationParameters
{
    XCTAssertTrue((@(paginationInfo.currentPageNumber) &&
                   paginationInfo.currentPageNumber == [paginationParameters[NBClientCurrentPageNumberKey] unsignedIntegerValue]),
                  @"Pagination info should be properly populated.");
    XCTAssertNotNil(@(paginationInfo.numberOfTotalPages),
                    @"Pagination info should be properly populated.");
    XCTAssertTrue((@(paginationInfo.numberOfItemsPerPage) &&
                   paginationInfo.numberOfItemsPerPage == [paginationParameters[NBClientNumberOfItemsPerPageKey] unsignedIntegerValue]),
                  @"Pagination info should be properly populated.");
    XCTAssertNotNil(@(paginationInfo.numberOfTotalItems),
                    @"Pagination info should be properly populated.");
}

- (void)assertServiceError:(NSError *)error
{
    if (!error || error.domain != NBErrorDomain) {
        return;
    }
    if (error.code == NBClientErrorCodeService) {
        XCTFail(@"People service returned error %@", error);
    }
}

- (void)assertSessionDataTask:(NSURLSessionDataTask *)task
{
    XCTAssertTrue(task && task.state == NSURLSessionTaskStateRunning,
                  @"Client should have created and ran task.");
    NSLog(@"REQUEST: %@", task.currentRequest.nb_debugDescription);
}

#pragma mark - Tests

- (void)testFetchPeople
{
    [self setUpAsync];
    NSDictionary *paginationParameters = @{ NBClientCurrentPageNumberKey: @1,
                                            NBClientNumberOfItemsPerPageKey: @5 };
    NBPaginationInfo *paginationInfo =
    [[NBPaginationInfo alloc] initWithDictionary:paginationParameters];
    NSURLSessionDataTask *task =
    [self.client
     fetchPeopleWithPaginationInfo:&paginationInfo
     completionHandler:^(NSArray *items, NSError *error) {
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
    NBPaginationInfo *paginationInfo =
    [[NBPaginationInfo alloc] initWithDictionary:paginationParameters];
    NSURLSessionDataTask *task =
    [self.client
     fetchPeopleByParameters:@{ @"city": @"Los Angeles" }
     withPaginationInfo:nil
     completionHandler:^(NSArray *items, NSError *error) {
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
    NSURLSessionDataTask *task =
    [self.client
     fetchPersonByIdentifier:self.userIdentifier
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
    NSURLSessionDataTask *task =
    [self.client
     fetchPersonByParameters:@{ @"email" : self.userEmailAddress }
     withCompletionHandler:^(NSDictionary *item, NSError *error) {
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
    NSURLSessionDataTask *task =
    [self.client
     createPersonWithParameters:parameters
     completionHandler:^(NSDictionary *item, NSError *error) {
         [self assertServiceError:error];
         [self assertPersonDictionary:item];
         XCTAssertTrue([item nb_containsDictionary:parameters],
                       @"Person dictionary should be populated by parameters.");
         [self completeAsync];
     }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testSavePerson
{
    [self setUpAsync];
    NSDictionary *parameters = @{ @"first_name": @"Foo", @"last_name": @"Bar" };
    void (^testSave)(NSDictionary *, NSError *) = ^(NSDictionary *item, NSError *error) {
        NSURLSessionDataTask *task =
        [self.client
         savePersonByIdentifier:self.userIdentifier
         withParameters:parameters
         completionHandler:^(NSDictionary *item, NSError *error) {
             [self assertServiceError:error];
             [self assertPersonDictionary:item];
             XCTAssertTrue([item nb_containsDictionary:parameters],
                           @"Person dictionary should be populated by parameters.");
             [self completeAsync];
         }];
        [self assertSessionDataTask:task];
    };
    [self.client fetchPersonByIdentifier:self.userIdentifier withCompletionHandler:testSave];
    [self tearDownAsync];
}

- (void)testDeletePerson
{
    [self setUpAsync];
    NSDictionary *parameters = @{ @"first_name": @"Foo", @"last_name": @"Bar" };
    void (^testDelete)(NSDictionary *, NSError *) = ^(NSDictionary *item, NSError *error) {
        NSURLSessionDataTask *task =
        [self.client
         deletePersonByIdentifier:[item[@"id"] unsignedIntegerValue]
         withCompletionHandler:^(NSDictionary *item, NSError *error) {
             [self assertServiceError:error];
             XCTAssertNil(item,
                          @"Person dictionary should not exist.");
             [self completeAsync];
         }];
        [self assertSessionDataTask:task];
    };
    [self.client createPersonWithParameters:parameters completionHandler:testDelete];
    [self tearDownAsync];
}

@end
