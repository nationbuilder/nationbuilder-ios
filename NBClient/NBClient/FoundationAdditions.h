//
//  FoundationAdditions.h
//  NBClient
//
//  Created by Peng Wang on 7/11/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSIndexSet (NBAdditions)

+ (NSIndexSet *)nb_indexSetOfSuccessfulHTTPStatusCodes;
+ (NSIndexSet *)nb_indexSetOfSuccessfulEmptyResponseHTTPStatusCodes;

@end

@interface NSDictionary (NBAdditions)

- (BOOL)nb_containsDictionary:(NSDictionary *)dictionary;

- (NSString *)nb_queryStringWithEncoding:(NSStringEncoding)stringEncoding
             skipPercentEncodingPairKeys:(NSSet *)skipPairKeys
              charactersToLeaveUnescaped:(NSString *)charactersToLeaveUnescaped;

@end

@interface NSString (NBAdditions)

- (NSString *)nb_percentEscapedQueryStringWithEncoding:(NSStringEncoding)stringEncoding
                            charactersToLeaveUnescaped:(NSString *)charactersToLeaveUnescaped;

@end

@interface NSURLRequest (NBAdditions)

- (NSString *)nb_debugDescription;

@end