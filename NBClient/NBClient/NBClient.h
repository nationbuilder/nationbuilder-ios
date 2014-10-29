//
//  NBClient.h
//  NBClient
//
//  Created by Peng Wang on 7/8/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NBDefines.h"

@class NBAuthenticator;
@class NBPaginationInfo;

@protocol NBClientDelegate;

typedef void (^NBClientResourceListCompletionHandler)(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error);
typedef void (^NBClientResourceItemCompletionHandler)(NSDictionary *item, NSError *error);

// Use these constants when working with the client's errors.
extern NSUInteger const NBClientErrorCodeService;
extern NSString * const NBClientErrorCodeKey;
extern NSString * const NBClientErrorHTTPStatusCodeKey;
extern NSString * const NBClientErrorMessageKey;
extern NSString * const NBClientErrorValidationErrorsKey;
extern NSString * const NBClientErrorInnerErrorKey;

extern NSString * const NBClientDefaultAPIVersion;
extern NSString * const NBClientDefaultBaseURLFormat;

@interface NBClient : NSObject <NSURLSessionDataDelegate, NBLogging>

@property (nonatomic, weak) id<NBClientDelegate> delegate;

@property (nonatomic, strong, readonly) NSString *nationName;
@property (nonatomic, strong, readonly) NSURLSession *urlSession;
@property (nonatomic, strong, readonly) NSURLSessionConfiguration *sessionConfiguration;

@property (nonatomic, strong, readonly) NBAuthenticator *authenticator;

@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, strong) NSString *apiVersion;

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

@protocol NBClientDelegate <NSObject>

@optional

// Default should return YES.
- (BOOL)client:(NBClient *)client shouldHandleResponse:(NSHTTPURLResponse *)response
                                            forRequest:(NSURLRequest *)request;
// Default should return YES.
- (BOOL)client:(NBClient *)client shouldHandleResponse:(NSHTTPURLResponse *)response
                                            forRequest:(NSURLRequest *)request
                                     withDataTaskError:(NSError *)error;
// Default should return YES. HTTP errors sometimes have additional values for the
// NBClientError* keys defined above.
- (BOOL)client:(NBClient *)client shouldHandleResponse:(NSHTTPURLResponse *)response
                                            forRequest:(NSURLRequest *)request
                                         withHTTPError:(NSError *)error;
// Default should return YES. Service errors have additional values for the
// NBClientError* keys defined above.
- (BOOL)client:(NBClient *)client shouldHandleResponse:(NSHTTPURLResponse *)response
                                            forRequest:(NSURLRequest *)request
                                      withServiceError:(NSError *)error;

@end
