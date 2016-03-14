//
//  NBClientPeopleTests.m
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBTestCase.h"

#import "FoundationAdditions.h"

#import "NBClient.h"
#import "NBClient+People.h"
#import "NBPaginationInfo.h"

@interface NBClientPeopleTests : NBTestCase

@property (nonatomic) NSDictionary *paginationParameters;

- (void)assertPeopleArray:(NSArray *)array;
- (void)assertPersonDictionary:(NSDictionary *)dictionary;

@end

@implementation NBClientPeopleTests

- (void)setUp
{
    [super setUp];
    [self setUpSharedClient];
    self.paginationParameters = @{ NBClientPaginationLimitKey: @5, NBClientPaginationTokenOptInKey: @1 };
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - Helpers

- (void)assertPeopleArray:(NSArray *)array
{
    XCTAssertNotNil(array, @"Client should have received list of people.");
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
        XCTAssertNotNil(dictionary[key], @"Person dictionary should have value for %@", key);
    }
}

#pragma mark - Tests

// NOTE: Using the pagination opt-in flag is needed for apps or tokens that
//       existed before the pagination change.

- (void)testFetchPeople
{
    [self setUpAsync];
    NSDictionary *paginationParameters = self.paginationParameters;
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"people" queryParameters:paginationParameters];
    }
    NBPaginationInfo *requestPaginationInfo = [[NBPaginationInfo alloc] initWithDictionary:paginationParameters legacy:NO];
    NSURLSessionDataTask *task =
    [self.client
     fetchPeopleWithPaginationInfo:requestPaginationInfo
     completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
         [self assertServiceError:error];
         [self assertPeopleArray:items];
         [self assertPaginationInfo:paginationInfo withPaginationParameters:paginationParameters];
         [self completeAsync];
     }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testFetchPeopleCount
{
    [self setUpAsync];
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"people/count" queryParameters:nil];
    }
    NSURLSessionDataTask *task = [self.client fetchPeopleCountWithCompletionHandler:^(id result, NSError *error) {
        [self assertServiceError:error];
        XCTAssert([result isKindOfClass:[NSNumber class]],
                  @"Client should have received people count.");
        [self completeAsync];
    }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testFetchPeopleByParameters
{
    [self setUpAsync];
    NSDictionary *paginationParameters = self.paginationParameters;
    NSDictionary *parameters = @{ @"state": @"CA" };
    if (self.shouldUseHTTPStubbing) {
        NSMutableDictionary *mutableParameters = paginationParameters.mutableCopy;
        [mutableParameters addEntriesFromDictionary:parameters];
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"people/search" queryParameters:mutableParameters];
    }
    NBPaginationInfo *requestPaginationInfo = [[NBPaginationInfo alloc] initWithDictionary:paginationParameters legacy:NO];
    NSURLSessionDataTask *task =
    [self.client
     fetchPeopleByParameters: parameters
     withPaginationInfo:requestPaginationInfo
     completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
         [self assertServiceError:error];
         [self assertPeopleArray:items];
         [self assertPaginationInfo:paginationInfo withPaginationParameters:paginationParameters];
         [self completeAsync];
     }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testFetchPeopleNearbyByLocationInfo
{
    [self setUpAsync];
    NSDictionary *paginationParameters = self.paginationParameters;
    NSDictionary *locationInfo = @{ NBClientLocationLatitudeKey: @34.049031f,
                                    NBClientLocationLongitudeKey: @(-118.25139f) };
    if (self.shouldUseHTTPStubbing) {
        NSMutableDictionary *mutableParameters = paginationParameters.mutableCopy;
        mutableParameters[@"location"] = [NSString stringWithFormat:@"%@,%@",
                                          locationInfo[NBClientLocationLatitudeKey], locationInfo[NBClientLocationLongitudeKey]];
        mutableParameters[@"distance"] = @1;
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"people/nearby" queryParameters:mutableParameters];
    }
    NBPaginationInfo *requestPaginationInfo = [[NBPaginationInfo alloc] initWithDictionary:paginationParameters legacy:NO];
    NSURLSessionDataTask *task =
    [self.client
     fetchPeopleNearbyByLocationInfo: locationInfo
     withPaginationInfo: requestPaginationInfo
     completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
         [self assertServiceError:error];
         [self assertPeopleArray:items];
         [self assertPaginationInfo:paginationInfo withPaginationParameters:paginationParameters];
         [self completeAsync];
     }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testFetchPerson
{
    [self setUpAsync];
    NSUInteger identifier = self.userIdentifier;
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" pathFormat:@"people/:id" pathVariables:@{ @"id": @(identifier) } queryParameters:nil];
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

- (void)testRegisterPerson
{
    [self setUpAsync];
    NSUInteger identifier = self.supporterIdentifier;
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" pathFormat:@"people/:id/register" pathVariables:@{ @"id": @(identifier) } queryParameters:nil];
    }
    NSURLSessionDataTask *task =
    [self.client
     registerPersonByIdentifier:identifier
     withCompletionHandler:^(NSDictionary *item, NSError *error) {
         [self assertServiceError:error];
         XCTAssertNil(item, @"Nothing should be returned.");
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
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"people/match" queryParameters:parameters];
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
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"people/me" queryParameters:nil];
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

// NOTE: Putting this here for now.
- (void)testCreatePersonPrivateNote
{
    [self setUpAsync];
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"POST" pathFormat:@"people/:id/notes" pathVariables:@{ @"id": @(self.userIdentifier) } queryParameters:nil];
    }
    NSDictionary *noteInfo = @{ NBClientNoteUserContentKey: @"He likes to plant apple trees." };
    NSURLSessionDataTask *task =
    [self.client createPersonPrivateNoteByIdentifier:self.userIdentifier withNoteInfo:noteInfo completionHandler:^(NSDictionary *item, NSError *error) {
        [self assertServiceError:error];
        NSArray *keys = @[ @"person_id", @"author_id", @"content" ];
        XCTAssertTrue([item nb_hasKeys:keys], "Note has correct attributes.");
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
        [self stubRequestUsingFileDataWithMethod:@"POST" path:@"people" queryParameters:nil];
    }
    void (^undoTestChanges)(NSUInteger) = ^(NSUInteger identifier) {
        [self.client deletePersonByIdentifier:identifier
                        withCompletionHandler:^(NSDictionary *item, NSError *error) { [self completeAsync]; }];
    };
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
             undoTestChanges([item[@"id"] unsignedIntegerValue]);
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
    void (^undoTestChanges)(void) = ^{
        [self.client savePersonByIdentifier:identifier withParameters:@{ @"demo": @"W" }
                          completionHandler:^(NSDictionary *item, NSError *error) { [self completeAsync]; }];
    };
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"PUT" pathFormat:@"people/:id" pathVariables:@{ @"id": @(identifier) } queryParameters:nil];
    }
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
             undoTestChanges();
         }
     }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testDeletePerson
{
    [self setUpAsync];
    NSUInteger identifier = 701;
    NBClientResourceItemCompletionHandler testDelete = ^(NSDictionary *item, NSError *error) {
        NSURLSessionDataTask *task =
        [self.client
         deletePersonByIdentifier:(!item ? identifier : [item[@"id"] unsignedIntegerValue])
         withCompletionHandler:^(NSDictionary *deletedItem, NSError *deleteError) {
             [self assertServiceError:deleteError];
             XCTAssertNil(deletedItem,
                          @"Person dictionary should not exist.");
             [self completeAsync];
         }];
        [self assertSessionDataTask:task];
    };
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"DELETE" pathFormat:@"people/:id" pathVariables:@{ @"id": @(identifier) } queryParameters:nil];
        testDelete(nil, nil);
    } else {
        [self completeAsync]; // FIXME
        NSDictionary *parameters = @{ @"first_name": @"Foo", @"last_name": @"Bar" };
        [self.client createPersonWithParameters:parameters completionHandler:testDelete];
    }
    [self tearDownAsync];
}

@end
