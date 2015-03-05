//
//  NBClientPeopleCapitalsTests.m
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import "NBTestCase.h"

#import "FoundationAdditions.h"

#import "NBClient.h"
#import "NBClient+People.h"

@interface NBClientPeopleCapitalsTests : NBTestCase

- (void)assertCapitalsArray:(NSArray *)array;
- (void)assertCapitalDictionary:(NSDictionary *)dictionary;

@end

@implementation NBClientPeopleCapitalsTests

- (void)setUp {
    [super setUp];
    [self setUpSharedClient];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - Helpers

- (void)assertCapitalsArray:(NSArray *)array
{
    XCTAssertNotNil(array,
                    @"Client should have received list of capitals.");
    for (NSDictionary *dictionary in array) {
        [self assertCapitalDictionary:dictionary];
    }
}

- (void)assertCapitalDictionary:(NSDictionary *)dictionary
{
    static NSArray *keys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keys = @[ @"id", @"person_id", @"author_id", @"type", @"amount_in_cents", @"created_at", @"content" ];
    });
    for (NSString *key in keys) {
        XCTAssertNotNil(dictionary[key],
                        @"Capital dictionary should have value for %@", key);
    }
}

#pragma mark - Tests

@end
