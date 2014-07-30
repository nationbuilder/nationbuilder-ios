//
//  NBClient.h
//  NBClient
//
//  Created by Peng Wang on 7/8/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NBAuthenticator;
@class NBPaginationInfo;

typedef void (^NBClientResourceListCompletionHandler)(NSArray *items, NSError *error);
typedef void (^NBClientResourceItemCompletionHandler)(NSDictionary *item, NSError *error);

extern NSUInteger const NBClientErrorCodeService;
extern NSString * const NBClientErrorCodeKey;
extern NSString * const NBClientErrorMessageKey;
extern NSString * const NBClientErrorValidationErrorsKey;
extern NSString * const NBClientErrorInnerErrorKey;

@interface NBClient : NSObject <NSURLSessionDelegate>

@property (nonatomic, strong, readonly) NSString *nationName;
@property (nonatomic, strong, readonly) NSURLSession *urlSession;
@property (nonatomic, strong, readonly) NSURLSessionConfiguration *sessionConfiguration;

@property (nonatomic, strong, readonly) NBAuthenticator *authenticator;

@property (nonatomic, strong) NSString *apiKey;

- (instancetype)initWithNationName:(NSString *)nationName
                     authenticator:(NBAuthenticator *)authenticator
                  customURLSession:(NSURLSession *)urlSession
     customURLSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration;

- (instancetype)initWithNationName:(NSString *)nationName
                            apiKey:(NSString *)apiKey
                     customBaseURL:(NSURL *)baseURL
                  customURLSession:(NSURLSession *)urlSession
     customURLSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration;

@end
