//
//  NBFoundationAdditionsTests.m
//  NBClient
//
//  Created by Peng Wang on 7/17/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NBTestCase.h"

#import "Main.h"

@interface NBFoundationAdditionsTests : NBTestCase @end

@implementation NBFoundationAdditionsTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testCheckingSuccessfulHTTPStatusCode
{
    NSUInteger statusCode = 404;
    XCTAssertFalse([[NSIndexSet nb_indexSetOfSuccessfulHTTPStatusCodes] containsIndex:statusCode],
                   @"%d status code should not be considered successful.", statusCode);
    statusCode = 200;
    XCTAssertTrue([[NSIndexSet nb_indexSetOfSuccessfulHTTPStatusCodes] containsIndex:statusCode],
                  @"%d status code should be considered successful.", statusCode);
}

- (void)testCheckingIfDictionaryContainsDictionary
{
    NSDictionary *source = @{ @"name": @"Foo Bar", @"age": @1, @"email": @"foo@bar.com" };
    NSDictionary *dictionary = @{ @"name": @"Foo Bar" };
    XCTAssertTrue([source nb_containsDictionary:dictionary],
                  @"Dictionary should be subset of source dictionary.");
}

- (void)testBuildingQueryStringFromDictionary
{
    NSDictionary *dictionary = @{ @"name": @"Foo Bar", @"age": @1, @"email": @"foo@bar.com" };
    NSString *queryString = [dictionary nb_queryStringWithEncoding:NSUTF8StringEncoding
                                       skipPercentEncodingPairKeys:[NSSet setWithObject:@"email"]
                                        charactersToLeaveUnescaped:nil];
    XCTAssertTrue([queryString isEqualToString:@"age=1&email=foo@bar.com&name=Foo%20Bar"],
                   @"Query string should be properly formed.");
}

- (void)testPercentEscapingQueryStringPairValue
{
    NSString *valueString = @"[ !\"#$%&'()*+,/]";
    NSString *escapedString = [valueString nb_percentEscapedQueryStringWithEncoding:NSUTF8StringEncoding
                                                         charactersToLeaveUnescaped:@"[]"];
    XCTAssertTrue([escapedString isEqualToString:@"[%20%21%22%23%24%25%26%27%28%29%2A%2B%2C%2F]"],
                  @"Query string should be properly formed.");
    NSString *escapedEscapedString = [escapedString nb_percentEscapedQueryStringWithEncoding:NSUTF8StringEncoding
                                                                  charactersToLeaveUnescaped:@"[]"];
    XCTAssertTrue([escapedEscapedString isEqualToString:@"[%2520%2521%2522%2523%2524%2525%2526%2527%2528%2529%252A%252B%252C%252F]"],
                  @"Query string should be properly formed.");
}

@end
