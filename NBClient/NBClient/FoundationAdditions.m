//
//  FoundationAdditions.m
//  NBClient
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "FoundationAdditions.h"

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
        indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(204, 1)];
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
        if (![dictionary[key] isEqual:self[key]]) {
            return NO;
        }
    }
    return YES;
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

- (NSDictionary *)nb_queryStringParametersWithEncoding:(NSStringEncoding)stringEncoding
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    NSArray *pairs = [self componentsSeparatedByString:QueryJoiner];
    for (NSString *pairString in pairs) {
        NSArray *pair = [pairString componentsSeparatedByString:QueryPairJoiner];
        NSString *key = [pair[0] nb_percentUnescapedQueryStringWithEncoding:NSUTF8StringEncoding
                                                   charactersToLeaveEscaped:nil];
        if (pair.count > 1) {
            NSString *valueString = [pair[1] nb_percentUnescapedQueryStringWithEncoding:NSUTF8StringEncoding
                                                               charactersToLeaveEscaped:nil];
            // TODO: Add support for collection-based data types.
            parameters[key] = valueString;
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
    // NOTE: Cocoapods suggests using a dedicated bundle
    NSString *localizedString = NSLocalizedStringFromTable(self, @"NationBuilder", nil);
    if ([localizedString isEqualToString:self]) {
        NBLog(@"WARNING: No localized string found for %@", self);
    }
    return localizedString;
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