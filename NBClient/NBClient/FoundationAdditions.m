//
//  FoundationAdditions.m
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import "FoundationAdditions.h"

#import "NBClient.h"
#import "NBDefines.h"

// The implementations are heavily inspired by AFNetworking.

@implementation NSIndexSet (NBAdditions)

+ (NSIndexSet *)nb_indexSetOfSuccessfulHTTPStatusCodes
{
    static NSIndexSet *indexSet;
    if (!indexSet) {
        indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    }
    return indexSet;
}

+ (NSIndexSet *)nb_indexSetOfSuccessfulEmptyResponseHTTPStatusCodes
{
    static NSIndexSet *indexSet;
    if (!indexSet) {
        indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(204, 100)];
    }
    return indexSet;
}

@end

static NSString *QueryJoiner = @"&";
static NSString *QueryPairJoiner = @"=";

@implementation NSDictionary (NBAdditions)

- (BOOL)nb_containsDictionary:(NSDictionary *)dictionary
{
    for (NSString *key in dictionary.allKeys) {
        id otherValue = dictionary[key];
        id value = self[key];
        if (![otherValue isEqual:value] &&
            !([otherValue isKindOfClass:[NSString class]] && [value isKindOfClass:[NSString class]] &&
              [otherValue isEqualToString:value]) &&
            !([otherValue isKindOfClass:[NSDictionary class]] && [value isKindOfClass:[NSDictionary class]] &&
              [value nb_containsDictionary:otherValue])
        ) {
            // NOTE: Arrays must be entirely contained (equal).
            return NO;
        }
    }
    return YES;
}

- (BOOL)nb_hasKeys:(NSArray *)keys
{
    SEL comparator = @selector(localizedCaseInsensitiveCompare:);
    NSArray *ownKeys = self.allKeys;
    if ([[ownKeys sortedArrayUsingSelector:comparator] isEqualToArray:[keys sortedArrayUsingSelector:comparator]]) {
        return true;
    }
    for (NSString *key in keys) {
        if (![ownKeys containsObject:key]) {
            return false;
        }
    }
    return true;
}

- (BOOL)nb_isEquivalentToDictionary:(NSDictionary *)dictionary
{
    if (dictionary.allKeys.count != self.allKeys.count) { return NO; }
    for (NSString *key in dictionary.allKeys) {
        id otherValue = dictionary[key];
        id value = self[key];
        if ([otherValue isKindOfClass:[NSDictionary class]] && [value isKindOfClass:[NSDictionary class]] &&
            [[otherValue allKeys] count] != [[value allKeys] count]
        ) {
            return NO;
        }
    }
    return [self nb_containsDictionary:dictionary];
}

- (NSString *)nb_queryString
{
    return [self nb_queryStringWithEncoding:NSUTF8StringEncoding skipPercentEncodingPairKeys:nil charactersToLeaveUnescaped:nil];
}

- (NSString *)nb_queryStringWithEncoding:(NSStringEncoding)stringEncoding
             skipPercentEncodingPairKeys:(NSSet *)skipPairKeys
              charactersToLeaveUnescaped:(NSString *)charactersToLeaveUnescaped
{
    NSMutableArray *mutablePairs = [NSMutableArray array];
    NSArray *keys = [self.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    for (NSString *key in keys) {
        id value = self[key];
        // TODO: Add support for collection-based data types.
        if ([value isKindOfClass:[NSArray class]] ||
            [value isKindOfClass:[NSDictionary class]] ||
            [value isKindOfClass:[NSSet class]]
        ) {
            NBLog(@"WARNING: Unable to serialize key %@ with value %@", key, value);
            continue;
        }
        NSString *valueString = [NSString stringWithFormat:@"%@", value];
        BOOL shouldPercentEncode = !skipPairKeys || ![skipPairKeys containsObject:key];
        NSString *pair = [NSString stringWithFormat:@"%@%@%@",
                          !shouldPercentEncode ? key :
                          [key nb_percentEscapedQueryStringWithEncoding:stringEncoding
                                             charactersToLeaveUnescaped:charactersToLeaveUnescaped],
                          QueryPairJoiner,
                          !shouldPercentEncode ? valueString :
                          [valueString nb_percentEscapedQueryStringWithEncoding:stringEncoding
                                                     charactersToLeaveUnescaped:charactersToLeaveUnescaped]];
        [mutablePairs addObject:pair];
    }
    return [mutablePairs componentsJoinedByString:QueryJoiner];
}

@end

@implementation NSString (NBAdditions)

- (NSString *)nb_percentEscapedQueryStringWithEncoding:(NSStringEncoding)stringEncoding
                            charactersToLeaveUnescaped:(NSString *)charactersToLeaveUnescaped
{
    static NSString *charactersToBeEscapedInQueryString = @":/?&=;+!@#$()',*";
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
    /* allocator: */ kCFAllocatorDefault,
    /* originalString: */ (__bridge CFStringRef)self,
    /* charactersToLeaveUnescaped: */ charactersToLeaveUnescaped ? (__bridge CFStringRef)charactersToLeaveUnescaped : NULL,
    /* legalURLCharactersToBeEscaped: */ (__bridge CFStringRef)charactersToBeEscapedInQueryString,
    /* encoding */ CFStringConvertNSStringEncodingToEncoding(stringEncoding));
}

- (NSDictionary *)nb_queryStringParameters
{
    return [self nb_queryStringParametersWithEncoding:NSUTF8StringEncoding];
}

- (NSDictionary *)nb_queryStringParametersWithEncoding:(NSStringEncoding)stringEncoding
{
    static NSNumberFormatter *numberFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        numberFormatter = [[NSNumberFormatter alloc] init];
        numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    });
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    NSArray *pairs = [self componentsSeparatedByString:QueryJoiner];
    for (NSString *pairString in pairs) {
        NSArray *pair = [pairString componentsSeparatedByString:QueryPairJoiner];
        NSString *key = [pair[0] nb_percentUnescapedQueryStringWithEncoding:NSUTF8StringEncoding
                                                   charactersToLeaveEscaped:nil];
        if (pair.count > 1) {
            id value;
            NSString *stringValue = [pair[1] nb_percentUnescapedQueryStringWithEncoding:NSUTF8StringEncoding
                                                  charactersToLeaveEscaped:nil];
            if ([stringValue nb_isNumeric]) {
                value = [numberFormatter numberFromString:stringValue];
            } else {
                value = stringValue;
            }
            // TODO: Add support for collection-based data types.
            parameters[key] = value;
        }
    }
    return [NSDictionary dictionaryWithDictionary:parameters];
}

- (NSString *)nb_percentUnescapedQueryStringWithEncoding:(NSStringEncoding)stringEncoding
                                charactersToLeaveEscaped:(NSString *)charactersToLeaveEscaped
{
    NSString *result = [self stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    return (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(
    /* allocator */ kCFAllocatorDefault,
    /* originalString: */ (__bridge CFStringRef)result,
    /* charactersToLeaveEscaped */ charactersToLeaveEscaped ? (__bridge CFStringRef)charactersToLeaveEscaped : CFSTR(""),
    /* encoding */ CFStringConvertNSStringEncodingToEncoding(stringEncoding));
}

- (NSString *)nb_localizedString
{
    NSBundle *bundle = [NSBundle bundleForClass:[NBClient class]];
    NSString *localizedString = NSLocalizedStringFromTableInBundle(self, @"NationBuilder", bundle, nil);
    if ([localizedString isEqualToString:self]) {
        NBLog(@"WARNING: No localized string found for %@", self);
    }
    return localizedString;
}

- (BOOL)nb_isNumeric
{
    static NSString *decimalDigitAndPointCharacterSet = @"1234567890.";
    return [[NSCharacterSet characterSetWithCharactersInString:decimalDigitAndPointCharacterSet] isSupersetOfSet:
            [NSCharacterSet characterSetWithCharactersInString:self]];
}

@end

@implementation NSURLRequest (NBAdditions)

- (NSString *)nb_debugDescription
{
    NSMutableURLRequest *request = self.mutableCopy;
    return [NSString stringWithFormat:
            @"%@\n"
            @"METHOD: %@\n"
            @"HEADERS: %@\n"
            @"BODY: %@\n",
            request.debugDescription,
            request.HTTPMethod,
            request.allHTTPHeaderFields,
            [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]];
}

@end

@implementation NSError (NBAdditions)

+ (NSError *)nb_genericError
{
    return [NSError
     errorWithDomain:NBErrorDomain code:0
     userInfo:@{ NSLocalizedDescriptionKey: @"title.unknown-error".nb_localizedString,
                 NSLocalizedFailureReasonErrorKey: @"message.unknown-error".nb_localizedString }];
}

@end
