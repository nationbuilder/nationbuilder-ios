//
//  NBDefines.h
//  NBClient
//
//  Created by Peng Wang on 7/10/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const NBErrorDomain;

// Names for a dedicated NationBuilder Info.plist file, which is the suggested
// method for storing relevant configuration.
extern NSString * const NBInfoFileName;
extern NSString * const NBInfoDevelopmentKey;
extern NSString * const NBInfoProductionKey;
extern NSString * const NBInfoBaseURLFormatKey;
extern NSString * const NBInfoClientIdentifierKey;
extern NSString * const NBInfoNationNameKey;
extern NSString * const NBInfoTestTokenKey;

typedef void (^NBGenericCompletionHandler)(NSError *error);

@protocol NBDictionarySerializing <NSObject>

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionary;
- (BOOL)isEqualToDictionary:(NSDictionary *)dictionary;

@end