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

@property (nonatomic, strong) NSString *apiKey; // Set this upon successful authentication.
@property (nonatomic, strong) NSString *apiVersion; // Optional. For future use.

// The main initializer.
- (instancetype)initWithNationName:(NSString *)nationName
                     authenticator:(NBAuthenticator *)authenticator
                  customURLSession:(NSURLSession *)urlSession
     customURLSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration;

// The alternate initializer for developing using pre-generated API tokens.
// Using this approach is discouraged unless you're confident about how securely
// you are storing the token.
- (instancetype)initWithNationName:(NSString *)nationName
                            apiKey:(NSString *)apiKey
                     customBaseURL:(NSURL *)baseURL
                  customURLSession:(NSURLSession *)urlSession
     customURLSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration;

@end

@protocol NBClientDelegate <NSObject>

@optional

// Useful for parsing for data outside of what is normally parsed and returned.
// In theory you would never need to do this, but this is a backup measure for when
// the API updates faster than this client.
- (void)client:(NBClient *)client didParseJSON:(NSDictionary *)jsonObject
                                  fromResponse:(NSHTTPURLResponse *)response
                                    forRequest:(NSURLRequest *)request;

// Useful for when you just want to create the data tasks but perhaps start them
// at a later time, and perhaps with more coordination, ie. with rate limits. By
// default, this method, if implemented, should return YES.
- (BOOL)client:(NBClient *)client shouldAutomaticallyStartDataTask:(NSURLSessionDataTask *)task;

// These 'shouldHandleResponse' methods allow you to halt default response
// handling at any error. For example, the accounts layer uses the 'HTTPError'
// variant to automatically sign out of the account that has the client.
// By default, these methods, if implemented, should return YES.
- (BOOL)client:(NBClient *)client shouldHandleResponse:(NSHTTPURLResponse *)response
                                            forRequest:(NSURLRequest *)request;
- (BOOL)client:(NBClient *)client shouldHandleResponse:(NSHTTPURLResponse *)response
                                            forRequest:(NSURLRequest *)request
                                     withDataTaskError:(NSError *)error;
// HTTP errors sometimes have additional values for the NBClientError* keys defined above.
- (BOOL)client:(NBClient *)client shouldHandleResponse:(NSHTTPURLResponse *)response
                                            forRequest:(NSURLRequest *)request
                                         withHTTPError:(NSError *)error;
// Service errors have additional values for the NBClientError* keys defined above.
- (BOOL)client:(NBClient *)client shouldHandleResponse:(NSHTTPURLResponse *)response
                                            forRequest:(NSURLRequest *)request
                                      withServiceError:(NSError *)error;

// Useful for configuring any requests before they go out, ie. adding custom headers.
- (void)client:(NBClient *)client willCreateDataTaskForRequest:(NSMutableURLRequest *)request;

@end
