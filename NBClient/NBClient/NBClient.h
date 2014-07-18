//
//  NBClient.h
//  NBClient
//
//  Created by Peng Wang on 7/8/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NBAuthenticator;

typedef void (^NBClientResourceListCompletionHandler)(NSArray *items, NSError *error);
typedef void (^NBClientResourceItemCompletionHandler)(NSDictionary *item, NSError *error);

extern NSUInteger const NBClientErrorCodeService;

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
                  customURLSession:(NSURLSession *)urlSession
     customURLSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration;

// People

- (NSURLSessionDataTask *)fetchPeopleWithCompletionHandler:(NBClientResourceListCompletionHandler)completionHandler;

- (NSURLSessionDataTask *)fetchPeopleByParameters:(NSDictionary *)parameters
                            withCompletionHandler:(NBClientResourceListCompletionHandler)completionHandler;

- (NSURLSessionDataTask *)fetchPersonByIdentifier:(NSUInteger)identifier
                            withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler;

- (NSURLSessionDataTask *)fetchPersonByParameters:(NSDictionary *)parameters
                            withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler;

- (NSURLSessionDataTask *)createPersonWithParameters:(NSDictionary *)parameters
                                   completionHandler:(NBClientResourceItemCompletionHandler)completionHandler;

- (NSURLSessionDataTask *)savePersonByIdentifier:(NSUInteger)identifier
                                  withParameters:(NSDictionary *)parameters
                               completionHandler:(NBClientResourceItemCompletionHandler)completionHandler;

- (NSURLSessionDataTask *)deletePersonByIdentifier:(NSUInteger)identifier
                             withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler;


@end
