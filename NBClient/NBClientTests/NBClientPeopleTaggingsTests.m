//
//  NBClientPeopleTaggingsTests.m
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBTestCase.h"

#import "FoundationAdditions.h"

#import "NBClient.h"
#import "NBClient+People.h"

@interface NBClientPeopleTaggingsTests : NBTestCase

@property (nonatomic) NSArray *tagList;
@property (nonatomic) NSString *tagName;

- (void)assertTaggingsArray:(NSArray *)array;
- (void)assertTaggingDictionary:(NSDictionary *)dictionary;

@end

@implementation NBClientPeopleTaggingsTests

- (void)setUp
{
    [super setUp];
    [self setUpSharedClient];
    self.tagList = @[ @"test 1", @"test 2" ];
    self.tagName = @"test";
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - Helpers

- (void)assertTaggingsArray:(NSArray *)array
{
    XCTAssertNotNil(array, @"Client should have received list of taggings.");
    for (NSDictionary *dictionary in array) { [self assertTaggingDictionary:dictionary]; }
}

- (void)assertTaggingDictionary:(NSDictionary *)dictionary
{
    static NSArray *keys; static dispatch_once_t onceToken; dispatch_once(&onceToken, ^{
        keys = @[ @"person_id", @"tag", @"created_at" ];
    });
    return XCTAssertTrue([dictionary nb_hasKeys:keys], "Tagging has correct attributes.");
}

#pragma mark - Tests

- (void)testFetchPersonTaggings
{
    [self setUpAsync];
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" pathFormat:@"people/:id/taggings" pathVariables:@{ @"id": @(self.userIdentifier) } queryParameters:nil];
    }
    NSURLSessionDataTask *task =
    [self.client fetchPersonTaggingsByIdentifier:self.userIdentifier withCompletionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
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
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"PUT" pathFormat:@"people/:id/taggings" pathVariables:@{ @"id": @(self.userIdentifier) } queryParameters:nil];
    }
    dispatch_block_t undoTestChanges = ^{
        [self.client deletePersonTaggingsByIdentifier:self.userIdentifier tagNames:@[ self.tagName ]
                                withCompletionHandler:^(NSDictionary *item, NSError *error) { [self completeAsync]; }];
    };
    NSURLSessionDataTask *task =
    [self.client
     createPersonTaggingByIdentifier:self.userIdentifier
     withTaggingInfo:@{ NBClientTaggingTagNameOrListKey: self.tagName }
     completionHandler:^(NSDictionary *item, NSError *error) {
         [self assertServiceError:error];
         [self assertTaggingDictionary:item];
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
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"PUT" pathFormat:@"people/:id/taggings" pathVariables:@{ @"id": @(self.userIdentifier) } queryParameters:nil
                                         variant:@"bulk" client:nil];
    }
    dispatch_block_t undoTestChanges = ^{
        [self.client deletePersonTaggingsByIdentifier:self.userIdentifier tagNames:self.tagList
                                withCompletionHandler:^(NSDictionary *item, NSError *error) { [self completeAsync]; }];
    };
    NSURLSessionDataTask *task =
    [self.client
     createPersonTaggingsByIdentifier:self.userIdentifier
     withTaggingInfo:@{ NBClientTaggingTagNameOrListKey: self.tagList }
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

- (void)testDeletePersonTagging
{
    [self setUpAsync];
    NBClientResourceItemCompletionHandler testDelete = ^(NSDictionary *item, NSError *error) {
        NSURLSessionDataTask *task =
        [self.client
         deletePersonTaggingsByIdentifier:self.userIdentifier
         tagNames:@[ self.tagName ]
         withCompletionHandler:^(NSDictionary *deletedItem, NSError *deleteError) {
             [self assertServiceError:deleteError];
             XCTAssertNil(deletedItem, @"Tagging should not exist.");
             [self completeAsync];
         }];
        [self assertSessionDataTask:task];
    };
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"DELETE" pathFormat:@"people/:id/taggings/:tag"
                                   pathVariables:@{ @"id": @(self.userIdentifier), @"tag": self.tagName } queryParameters:nil];
        testDelete(nil, nil);
    } else {
        [self completeAsync]; // FIXME
        [self.client createPersonTaggingByIdentifier:self.userIdentifier withTaggingInfo:@{ NBClientTaggingTagNameOrListKey: self.tagName }
                                   completionHandler:testDelete];
    }
    [self tearDownAsync];
}

- (void)testDeletePersonTaggings
{
    [self setUpAsync];
    NBClientResourceListCompletionHandler testDelete = ^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
        NSURLSessionDataTask *task =
        [self.client
         deletePersonTaggingsByIdentifier:self.userIdentifier
         tagNames:self.tagList
         withCompletionHandler:^(NSDictionary *deletedItem, NSError *deleteError) {
             [self assertServiceError:deleteError];
             XCTAssertNil(deletedItem, @"Tagging should not exist.");
             [self completeAsync];
         }];
        [self assertSessionDataTask:task];
    };
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"DELETE" pathFormat:@"people/:id/taggings" pathVariables:@{ @"id": @(self.userIdentifier) } queryParameters:nil];
        testDelete(nil, nil, nil);
    } else {
        [self completeAsync]; // FIXME
        [self.client createPersonTaggingsByIdentifier:self.userIdentifier withTaggingInfo:@{ NBClientTaggingTagNameOrListKey: self.tagList }
                                    completionHandler:testDelete];
    }
    [self tearDownAsync];
}

@end
