//
//  NBClientContactsTests.m
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBTestCase.h"

#import "FoundationAdditions.h"

#import "NBClient.h"
#import "NBClient+Contacts.h"
#import "NBPaginationInfo.h"

@interface NBClientContactsTests : NBTestCase

- (void)assertContactsArray:(NSArray *)array;
- (void)assertContactDictionary:(NSDictionary *)dictionary;

- (void)assertContactTypesArray:(NSArray *)array;
- (void)assertContactMethodsArray:(NSArray *)array;
- (void)assertContactStatusesArray:(NSArray *)array;

@end

@implementation NBClientContactsTests

- (void)setUp
{
    [super setUp];
    [self setUpSharedClient];
}

#pragma mark - Contacts

#pragma mark Helpers

- (void)assertContactsArray:(NSArray *)array
{
    XCTAssertNotNil(array, @"Client should have received list of contacts.");
    for (NSDictionary *dictionary in array) { [self assertContactDictionary:dictionary]; }
}

- (void)assertContactDictionary:(NSDictionary *)dictionary
{
    static NSArray *keys; static dispatch_once_t onceToken; dispatch_once(&onceToken, ^{
        keys = @[ @"type_id", @"method", @"sender_id", @"recipient_id", @"status", @"broadcaster_id", @"note", @"created_at" ];
    });
    return XCTAssertTrue([dictionary nb_hasKeys:keys], "Contact has correct attributes.");
}

#pragma mark Tests

- (void)testFetchPersonContacts
{
    [self setUpAsync];
    NSDictionary *paginationParameters = @{ NBClientPaginationLimitKey: @5, NBClientPaginationTokenOptInKey: @1 };
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" pathFormat:@"people/:id/contacts" pathVariables:@{ @"id": @(self.supporterIdentifier) } queryParameters:paginationParameters];
    }
    NBPaginationInfo *requestPaginationInfo = [[NBPaginationInfo alloc] initWithDictionary:paginationParameters legacy:NO];
    NSURLSessionDataTask *task =
    [self.client fetchPersonContactsByIdentifier:self.supporterIdentifier withPaginationInfo:requestPaginationInfo completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
        [self assertServiceError:error];
        [self assertContactsArray:items];
        [self completeAsync];
    }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testCreatePersonContact
{
    [self setUpAsync];
    NSDictionary *contactInfo = @{ NBClientContactBroadcasterIdentifierKey: @1,
                                   NBClientContactMethodKey: @"door_knock",
                                   NBClientContactNoteKey: @"He did not support the cause.",
                                   NBClientContactSenderIdentifierKey: @(self.userIdentifier),
                                   NBClientContactStatusKey: @"not_interested",
                                   NBClientContactTypeIdentifierKey: @4 };
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"POST" pathFormat:@"people/:id/contacts" pathVariables:@{ @"id": @(self.supporterIdentifier) } queryParameters:nil];
    }
    NSURLSessionDataTask *task =
    [self.client createPersonContactByIdentifier:self.supporterIdentifier withContactInfo:contactInfo completionHandler:^(NSDictionary *item, NSError *error) {
        [self assertServiceError:error];
        [self assertContactDictionary:item];
        [self completeAsync];
    }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

#pragma mark - Contact Types (Fetch Only)

#pragma mark Helpers

- (void)assertContactTypesArray:(NSArray *)array
{
    XCTAssertNotNil(array, @"Client should have received list of contact types.");
    NSArray *keys = @[ @"id", @"name" ];
    for (NSDictionary *dictionary in array) {
        XCTAssertTrue([dictionary nb_hasKeys:keys], "Contact has correct attributes.");
    }
}

- (void)assertContactMethodsArray:(NSArray *)array
{
    XCTAssertNotNil(array, @"Client should have received list of contact methods.");
    NSArray *keys = @[ @"api_name", @"name" ];
    for (NSDictionary *dictionary in array) {
        XCTAssertTrue([dictionary nb_hasKeys:keys], "Contact status has correct attributes.");
    }
}

- (void)assertContactStatusesArray:(NSArray *)array
{
    XCTAssertNotNil(array, @"Client should have received list of contact statuses.");
    NSArray *keys = @[ @"api_name", @"name" ];
    for (NSDictionary *dictionary in array) {
        XCTAssertTrue([dictionary nb_hasKeys:keys], "Contact status has correct attributes.");
    }
}

#pragma mark Tests

- (void)testFetchContactTypes
{
    [self setUpAsync];
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"settings/contact_types" queryParameters:nil];
    }
    NSURLSessionDataTask *task =
    [self.client fetchContactTypesWithPaginationInfo:nil completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
        [self assertServiceError:error];
        [self assertContactTypesArray:items];
        [self completeAsync];
    }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testFetchContactMethods
{
    [self setUpAsync];
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"settings/contact_methods" queryParameters:nil];
    }
    NSURLSessionDataTask *task =
    [self.client fetchContactMethodsWithCompletionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
        [self assertServiceError:error];
        [self assertContactMethodsArray:items];
        [self completeAsync];
    }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testFetchContactStatuses
{
    [self setUpAsync];
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" path:@"settings/contact_statuses" queryParameters:nil];
    }
    NSURLSessionDataTask *task =
    [self.client fetchContactStatusesWithCompletionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
        [self assertServiceError:error];
        [self assertContactStatusesArray:items];
        [self completeAsync];
    }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

@end
