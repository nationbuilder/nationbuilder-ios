//
//  FoundationAdditions.m
//  NBClient
//
//  Created by Peng Wang on 7/11/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "FoundationAdditions.h"

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
    static NSString *pairFormat = @"%@=%@";
    static NSString *joiner = @"&";
    NSMutableArray *mutablePairs = [NSMutableArray array];
    NSArray *keys = [self.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    for (NSString *key in keys) {
        id value = self[key];
        // TODO: Add support for collection-based data types.
        if ([value isKindOfClass:[NSArray class]] ||
            [value isKindOfClass:[NSDictionary class]] ||
            [value isKindOfClass:[NSSet class]]
            ) {
            NSLog(@"WARNING: Unable to serialize key %@ with value %@", key, value);
            continue;
        }
        NSString *valueString = [NSString stringWithFormat:@"%@", value];
        BOOL shouldPercentEncode = !skipPairKeys || ![skipPairKeys containsObject:key];
        NSString *pair = [NSString stringWithFormat:pairFormat,
                          !shouldPercentEncode ? key :
                          [key nb_percentEscapedQueryStringWithEncoding:stringEncoding
                                             charactersToLeaveUnescaped:charactersToLeaveUnescaped],
                          !shouldPercentEncode ? valueString :
                          [valueString nb_percentEscapedQueryStringWithEncoding:stringEncoding
                                                     charactersToLeaveUnescaped:charactersToLeaveUnescaped]];
        [mutablePairs addObject:pair];
    }
    return [mutablePairs componentsJoinedByString:joiner];
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