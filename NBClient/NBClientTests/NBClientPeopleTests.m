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

#pragma mark - Tests

// NOTE: Using the pagination opt-in flag is needed for apps or tokens that
//       existed before the pagination change.

- (void)testFetchPeople
{
    [self setUpAsync];
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"people" queryParameters:self.paginationParameters];
    }
    [self.client
     fetchPeopleWithPaginationInfo:[[NBPaginationInfo alloc] initWithDictionary:self.paginationParameters legacy:NO]
     completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
         [self assertServiceError:error];
         [self assertPeopleArray:items];
         [self assertPaginationInfo:paginationInfo withPaginationParameters:self.paginationParameters];
         [self completeAsync];
     }];
    [self tearDownAsync];
}

- (void)testFetchPeopleCount
{
    [self setUpAsync];
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"people/count" queryParameters:nil];
    }
    [self.client fetchPeopleCountWithCompletionHandler:^(id result, NSError *error) {
        [self assertServiceError:error];
        XCTAssert([result isKindOfClass:[NSNumber class]],
                  @"Client should have received people count.");
        [self completeAsync];
    }];
    [self tearDownAsync];
}

- (void)testFetchPeopleByParameters
{
    [self setUpAsync];
    NSDictionary *parameters = @{ @"state": @"CA" };
    if (self.shouldUseHTTPStubbing) {
        NSMutableDictionary *mutableParameters = self.paginationParameters.mutableCopy;
        [mutableParameters addEntriesFromDictionary:parameters];
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"people/search" queryParameters:mutableParameters];
    }
    [self.client
     fetchPeopleByParameters: parameters
     withPaginationInfo:[[NBPaginationInfo alloc] initWithDictionary:self.paginationParameters legacy:NO]
     completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
         [self assertServiceError:error];
         [self assertPeopleArray:items];
         [self assertPaginationInfo:paginationInfo withPaginationParameters:self.paginationParameters];
         [self completeAsync];
     }];
    [self tearDownAsync];
}

- (void)testFetchPeopleNearbyByLocationInfo
{
    [self setUpAsync];
    NSNumber *latitude = @(34.049031f); NSNumber *longtitude = @(-118.25139f);
    if (self.shouldUseHTTPStubbing) {
        NSMutableDictionary *mutableParameters = self.paginationParameters.mutableCopy;
        mutableParameters[@"location"] = [NSString stringWithFormat:@"%@,%@", latitude, longtitude];
        mutableParameters[@"distance"] = @1;
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"people/nearby" queryParameters:mutableParameters];
    }
    [self.client
     fetchPeopleNearbyByLocationInfo: @{ NBClientLocationLatitudeKey: latitude, NBClientLocationLongitudeKey: longtitude }
     withPaginationInfo: [[NBPaginationInfo alloc] initWithDictionary:self.paginationParameters legacy:NO]
     completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
         [self assertServiceError:error];
         [self assertPeopleArray:items];
         [self assertPaginationInfo:paginationInfo withPaginationParameters:self.paginationParameters];
         [self completeAsync];
     }];
    [self tearDownAsync];
}

- (void)testFetchPerson
{
    [self setUpAsync];
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" pathFormat:@"people/:id" pathVariables:@{ @"id": @(self.userIdentifier) } queryParameters:nil];
    }
    [self.client fetchPersonByIdentifier:self.userIdentifier withCompletionHandler:^(NSDictionary *item, NSError *error) {
        [self assertServiceError:error];
        [self assertPersonDictionary:item];
        [self completeAsync];
    }];
    [self tearDownAsync];
}

- (void)testRegisterPerson
{
    [self setUpAsync];
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" pathFormat:@"people/:id/register" pathVariables:@{ @"id": @(self.supporterIdentifier) } queryParameters:nil];
    }
    [self.client registerPersonByIdentifier:self.supporterIdentifier withCompletionHandler:^(NSDictionary *item, NSError *error) {
        [self assertServiceError:error];
        XCTAssertNil(item, @"Nothing should be returned.");
        [self completeAsync];
    }];
    [self tearDownAsync];
}

- (void)testFetchPersonByParameters
{
    [self setUpAsync];
    NSDictionary *parameters = @{ @"email" : self.userEmailAddress };
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"people/match" queryParameters:parameters];
    }
    [self.client fetchPersonByParameters: parameters withCompletionHandler:^(NSDictionary *item, NSError *error) {
        [self assertServiceError:error];
        [self assertPersonDictionary:item];
        [self completeAsync];
    }];
    [self tearDownAsync];
}

- (void)testFetchPersonByClientParameters
{
    [self setUpAsync];
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"people/me" queryParameters:nil];
    }
    [self.client fetchPersonForClientUserWithCompletionHandler:^(NSDictionary *item, NSError *error) {
        [self assertServiceError:error];
        [self assertPersonDictionary:item];
        [self completeAsync];
    }];
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
    [self.client createPersonPrivateNoteByIdentifier:self.userIdentifier withNoteInfo:noteInfo completionHandler:^(NSDictionary *item, NSError *error) {
        [self assertServiceError:error];
        NSArray *keys = @[ @"person_id", @"author_id", @"content" ];
        XCTAssertTrue([item nb_hasKeys:keys], "Note has correct attributes.");
        [self completeAsync];
    }];
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
    [self.client createPersonWithParameters:parameters completionHandler:^(NSDictionary *item, NSError *error) {
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
    [self tearDownAsync];
}

- (void)testSavePerson
{
    [self setUpAsync];
    NSDictionary *parameters = @{ @"demo": @"B" };
    dispatch_block_t undoTestChanges = ^{
        [self.client savePersonByIdentifier:self.userIdentifier withParameters:@{ @"demo": @"W" }
                          completionHandler:^(NSDictionary *item, NSError *error) { [self completeAsync]; }];
    };
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"PUT" pathFormat:@"people/:id" pathVariables:@{ @"id": @(self.userIdentifier) } queryParameters:nil];
    }
    [self.client savePersonByIdentifier:self.userIdentifier withParameters:parameters completionHandler:^(NSDictionary *item, NSError *error) {
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
    [self tearDownAsync];
}

- (void)testDeletePerson
{
    [self setUpAsync];
    NSUInteger identifier = 701;
    NBClientResourceItemCompletionHandler testDelete = ^(NSDictionary *item, NSError *error) {
        [self.client
         deletePersonByIdentifier:(!item ? identifier : [item[@"id"] unsignedIntegerValue])
         withCompletionHandler:^(NSDictionary *deletedItem, NSError *deleteError) {
             [self assertServiceError:deleteError];
             XCTAssertNil(deletedItem,
                          @"Person dictionary should not exist.");
             [self completeAsync];
         }];
    };
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"DELETE" pathFormat:@"people/:id" pathVariables:@{ @"id": @(identifier) } queryParameters:nil];
        testDelete(nil, nil);
    } else {
        NSDictionary *parameters = @{ @"first_name": @"Foo", @"last_name": @"Bar" };
        [self.client createPersonWithParameters:parameters completionHandler:testDelete];
    }
    [self tearDownAsync];
}

@end
