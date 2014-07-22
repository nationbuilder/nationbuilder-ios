//
//  NBDefines.h
//  NBClient
//
//  Created by Peng Wang on 7/10/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const NBErrorDomain;

@protocol NBDictionarySerializing <NSObject>

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionary;
- (BOOL)isEqualToDictionary:(NSDictionary *)dictionary;

@end