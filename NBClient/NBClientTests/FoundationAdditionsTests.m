//
//  FoundationAdditionsTests.m
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import <XCTest/XCTest.h>

#import "NBTestCase.h"

#import "FoundationAdditions.h"

@interface FoundationAdditionsTests : NBTestCase @end

@implementation FoundationAdditionsTests

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
                   @"%lu status code should not be considered successful.", (unsigned long)statusCode);
    statusCode = 200;
    XCTAssertTrue([[NSIndexSet nb_indexSetOfSuccessfulHTTPStatusCodes] containsIndex:statusCode],
                  @"%lu status code should be considered successful.", (unsigned long)statusCode);
}

- (void)testCheckingSuccessfulEmptyResponseHTTPStatusCode
{
    NSUInteger statusCode = 204;
    XCTAssertTrue([[NSIndexSet nb_indexSetOfSuccessfulEmptyResponseHTTPStatusCodes] containsIndex:statusCode],
                  @"%lu status code should be considered successful.", (unsigned long)statusCode);
}

- (void)testCheckingIfDictionaryContainsDictionary
{
    NSDictionary *source = @{ @"name": @"Foo Bar", @"age": @1, @"email": @"foo@bar.com",
                              @"collection": @{ @"foo": @"foo", @"bar": @"bar", @"baz": @"baz" } };
    NSDictionary *dictionary = @{ @"name": @"Foo Bar",
                                  @"collection": @{ @"foo": @"foo", @"bar": @"bar" } };
    NSDictionary *uncontainedDictionary = @{ @"not": @"contained" };
    XCTAssertTrue([source nb_containsDictionary:dictionary],
                  @"Dictionary should be subset of source dictionary.");
    XCTAssertFalse([source nb_containsDictionary:uncontainedDictionary],
                   @"Dictionary should not be subset of source dictionary.");
}

- (void)testCheckingIfDictionaryHasKeys
{
    NSDictionary *dictionary = @{ @"foo": @0, @"bar": @1 };
    NSArray *keys = @[ @"foo", @"bar" ];
    NSArray *subsetKeys = @[ @"foo" ];
    NSArray *unorderedKeys = @[ @"bar", @"foo" ];
    XCTAssertTrue([dictionary nb_hasKeys:keys], @"Dictionary should have keys.");
    XCTAssertTrue([dictionary nb_hasKeys:subsetKeys], @"Dictionary should have keys.");
    XCTAssertTrue([dictionary nb_hasKeys:unorderedKeys], @"Should test regardless of key order.");
    NSArray *otherKeys = @[ @"baz" ];
    NSArray *supersetKeys = @[ @"foo", @"bar", @"baz" ];
    XCTAssertFalse([dictionary nb_hasKeys:otherKeys], @"Dictionary should not have keys.");
    XCTAssertFalse([dictionary nb_hasKeys:supersetKeys], @"Should test for having all given keys.");
}

- (void)testCheckingIfDictionariesAreEquivalent
{
    NSDictionary *source = @{ @"foo": @"foo", @"bar": @{ @"baz": @1 } };
    NSDictionary *dictionary = @{ @"foo": @"foo", @"bar": @{ @"baz": @1 } };
    XCTAssertTrue([source nb_isEquivalentToDictionary:source],
                  @"Dictionaries should be equivalent if identical.");
    XCTAssertTrue([source nb_isEquivalentToDictionary:dictionary],
                  @"Dictionaries should be equivalent if non-identical.");

    source = @{ @"foo": @"foo" };
    dictionary = @{ @"foo": @"foo" };
    NSDictionary *queryParameters = dictionary.nb_queryString.nb_queryStringParameters;
    XCTAssertTrue([source nb_isEquivalentToDictionary:queryParameters],
                  @"Dictionaries should be equivalent even if strings aren't equal in terms of encoding.");
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

- (void)testConvertingObjectToNilIfNull
{
    XCTAssertNil([[NSNull null] nb_nilIfNull], @"New object from NSNull should be nil.");
    XCTAssertNotNil([[NSObject alloc] init], @"New object from anything else non-nil should not be nil.");
}

- (void)testPercentEscapingQueryStringPairValue
{
    NSString *valueString = @"[ !\"#$%&'()*+,/]";
    NSString *escapedString = [valueString nb_percentEscapedQueryStringWithEncoding:NSUTF8StringEncoding
                                                         charactersToLeaveUnescaped:@"[]"];
    XCTAssertTrue([escapedString isEqualToString:@"%5B%20%21%22%23%24%25%26%27%28%29%2A%2B%2C%2F%5D"],
                  @"Query string value should be properly formed.");

    NSString *escapedEscapedString = [escapedString nb_percentEscapedQueryStringWithEncoding:NSUTF8StringEncoding
                                                                  charactersToLeaveUnescaped:@"[]"];
    XCTAssertTrue([escapedEscapedString isEqualToString:@"%255B%2520%2521%2522%2523%2524%2525%2526%2527%2528%2529%252A%252B%252C%252F%255D"],
                  @"Query string value should be properly formed.");
}

- (void)testPercentUnescapingQueryStringPairValue
{
    NSString *escapedString = @"%20%21%22%23%24%25%26%27%28%29%2A%2B%2C%2F";
    NSString *unescapedString = [escapedString nb_percentUnescapedQueryStringWithEncoding:NSUTF8StringEncoding
                                                                 charactersToLeaveEscaped:nil];
    XCTAssertTrue([unescapedString isEqualToString:@" !\"#$%&'()*+,/"],
                  @"Query string value should be properly formed.");
}

- (void)testBuildingDictionaryFromQueryString
{
    NSString *string = @"age=1&email=foo@bar.com&name=Foo%20Bar";
    NSDictionary *parameters = string.nb_queryStringParameters;
    NSDictionary *expectedParameters = @{ @"name": @"Foo Bar", @"age": @1, @"email": @"foo@bar.com" };
    XCTAssertEqualObjects(parameters, expectedParameters,
                          @"Query parameters should be properly formed");
}

- (void)testCheckingIfStringIsNumeric
{
    XCTAssertTrue(@"1".nb_isNumeric, @"Whole numbers should be numeric.");
    XCTAssertTrue(@"1.1".nb_isNumeric, @"Decimal numbers should be numeric.");
    XCTAssertFalse(@"1-111-111-1111".nb_isNumeric, @"Phone numbers (numbers with dashes) should not be numeric.");
    XCTAssertFalse(@"1,111,111,1111".nb_isNumeric, @"Formatted numbers (comma-delimited) should not be numeric.");
    XCTAssertFalse(@"abc123".nb_isNumeric, @"Strings that are partially numeric should not be numeric.");
}

@end
