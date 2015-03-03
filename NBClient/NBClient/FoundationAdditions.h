//
//  FoundationAdditions.h
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSIndexSet (NBAdditions)

+ (NSIndexSet *)nb_indexSetOfSuccessfulHTTPStatusCodes;
+ (NSIndexSet *)nb_indexSetOfSuccessfulEmptyResponseHTTPStatusCodes;

@end

@interface NSDictionary (NBAdditions)

- (BOOL)nb_containsDictionary:(NSDictionary *)dictionary;

- (BOOL)nb_isEquivalentToDictionary:(NSDictionary *)dictionary;

- (NSString *)nb_queryString;

- (NSString *)nb_queryStringWithEncoding:(NSStringEncoding)stringEncoding
             skipPercentEncodingPairKeys:(NSSet *)skipPairKeys
              charactersToLeaveUnescaped:(NSString *)charactersToLeaveUnescaped;

@end

@interface NSString (NBAdditions)

- (NSDictionary *)nb_queryStringParameters;

- (NSDictionary *)nb_queryStringParametersWithEncoding:(NSStringEncoding)stringEncoding;

- (NSString *)nb_percentEscapedQueryStringWithEncoding:(NSStringEncoding)stringEncoding
                            charactersToLeaveUnescaped:(NSString *)charactersToLeaveUnescaped;

- (NSString *)nb_percentUnescapedQueryStringWithEncoding:(NSStringEncoding)stringEncoding
                                charactersToLeaveEscaped:(NSString *)charactersToLeaveEscaped;

- (NSString *)nb_localizedString;

- (BOOL)nb_isNumeric;

@end

@interface NSURLRequest (NBAdditions)

- (NSString *)nb_debugDescription;

@end

@interface NSError (NBAdditions)

+ (NSError *)nb_genericError;

@end
