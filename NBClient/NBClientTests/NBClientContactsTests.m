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

@end

@implementation NBClientContactsTests

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

- (void)assertContactsArray:(NSArray *)array
{
    XCTAssertNotNil(array, @"Client should have received list of contacts.");
    for (NSDictionary *dictionary in array) {
        [self assertContactDictionary:dictionary];
    }
}

- (void)assertContactDictionary:(NSDictionary *)dictionary
{
    static NSArray *keys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keys = [@[ @"type_id", @"method", @"sender_id", @"recipient_id", @"status", @"broadcaster_id", @"note", @"created_at" ]
                sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    });
    XCTAssertEqualObjects([dictionary.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)], keys,
                          "Capital has correct attributes.");
}

#pragma mark - Tests

- (void)testFetchPersonContacts
{
    [self setUpAsync];
    NSDictionary *paginationParameters = @{ NBClientPaginationLimitKey: @5, NBClientPaginationTokenOptInKey: @1 };
    NSUInteger personIdentifier = self.supporterIdentifier;
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"GET" pathFormat:@"people/:id/contacts" pathVariables:@{ @"id": @(personIdentifier) } queryParameters:paginationParameters];
    }
    NBPaginationInfo *requestPaginationInfo = [[NBPaginationInfo alloc] initWithDictionary:paginationParameters legacy:NO];
    NSURLSessionDataTask *task =
    [self.client
     fetchPersonContactsByIdentifier:personIdentifier
     withPaginationInfo:requestPaginationInfo
     completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
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
    NSUInteger personIdentifier = self.supporterIdentifier;
    if (self.shouldUseHTTPStubbing) {
        [self stubRequestUsingFileDataWithMethod:@"POST" pathFormat:@"people/:id/contacts" pathVariables:@{ @"id": @(personIdentifier) } queryParameters:nil];
    }
    NSURLSessionDataTask *task =
    [self.client
     createPersonContactByIdentifier:personIdentifier
     withContactInfo:contactInfo
     completionHandler:^(NSDictionary *item, NSError *error) {
         [self assertServiceError:error];
         [self assertContactDictionary:item];
         [self completeAsync];
     }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

@end
