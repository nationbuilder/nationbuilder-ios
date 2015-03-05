//
//  NBClientPeopleTaggingsTests.m
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import "NBTestCase.h"

#import "FoundationAdditions.h"

#import "NBClient.h"
#import "NBClient+People.h"

@interface NBClientPeopleTaggingsTests : NBTestCase

- (void)assertTaggingsArray:(NSArray *)array;
- (void)assertTaggingDictionary:(NSDictionary *)dictionary;

@end

@implementation NBClientPeopleTaggingsTests

- (void)setUp {
    [super setUp];
    [self setUpSharedClient];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - Helpers

- (void)assertTaggingsArray:(NSArray *)array
{
    XCTAssertNotNil(array,
                    @"Client should have received list of taggings.");
    for (NSDictionary *dictionary in array) {
        [self assertTaggingDictionary:dictionary];
    }
}

- (void)assertTaggingDictionary:(NSDictionary *)dictionary
{
    static NSArray *keys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keys = @[ @"person_id", @"tag", @"created_at" ];
    });
    for (NSString *key in keys) {
        XCTAssertNotNil(dictionary[key],
                        @"Tagging dictionary should have value for %@", key);
    }
}

#pragma mark - Tests

- (void)testFetchPersonTaggings
{
    [self setUpAsync];
    NSUInteger personIdentifier = self.userIdentifier;
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"people/taggings" identifier:personIdentifier parameters:nil];
    }
    NSURLSessionDataTask *task =
    [self.client
     fetchPersonTaggingsByIdentifier:personIdentifier
     withCompletionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
         [self assertServiceError:error];
         [self assertTaggingsArray:items];
         [self completeAsync];
     }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testCreatePersonTagging
{
    [self setUpAsync];
    NSDictionary *taggingInfo = @{ NBClientTaggingTagNameOrListKey: @"test" };
    NSUInteger personIdentifier = self.userIdentifier;
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"PUT" path:@"people/tagging" identifier:personIdentifier parameters:nil];
    }
    void (^undoTestChanges)(void) = ^{
        // TODO
        [self completeAsync];
    };
    NSURLSessionDataTask *task =
    [self.client
     createPersonTaggingByIdentifier:personIdentifier
     withTaggingInfo:taggingInfo
     completionHandler:^(NSDictionary *item, NSError *error) {
         [self assertServiceError:error];
         [self assertTaggingDictionary:item];
         XCTAssertTrue([item nb_containsDictionary:taggingInfo],
                       @"Tagging dictionary should be populated by parameters.");
         if (self.shouldUseHTTPStubbing) {
             [self completeAsync];
         } else {
             undoTestChanges();
         }
     }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testCreatePersonTaggings
{
    [self setUpAsync];
    NSUInteger personIdentifier = self.userIdentifier;
    NSDictionary *taggingInfo = @{ NBClientTaggingTagNameOrListKey: @[ @"test 1", @"test 2" ] };
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"PUT" path:@"people/taggings" identifier:personIdentifier parameters:nil];
    }
    void (^undoTestChanges)(void) = ^{
        // TODO
        [self completeAsync];
    };
    NSURLSessionDataTask *task =
    [self.client
     createPersonTaggingsByIdentifier:personIdentifier
     withTaggingInfo:taggingInfo
     completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
         [self assertServiceError:error];
         [self assertTaggingsArray:items];
         if (self.shouldUseHTTPStubbing) {
             [self completeAsync];
         } else {
             undoTestChanges();
         }
     }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

@end
