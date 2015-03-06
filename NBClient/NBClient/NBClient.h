//
//  NBClient.h
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
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

// You can also get the default values for some properties.
extern NSString * const NBClientDefaultAPIVersion;
extern NSString * const NBClientDefaultBaseURLFormat;

extern NSString * const NBClientPaginationTokenOptInKey;

// NOTE: With the exception of the person resource, convenient key constants are
//       provided for request payload property names.
extern NSString * const NBClientLocationLatitudeKey;
extern NSString * const NBClientLocationLongitudeKey;
extern NSString * const NBClientLocationProximityDistanceKey; // Integer, radius in miles.

extern NSString * const NBClientTaggingTagNameOrListKey; // String or array for bulk operations.

extern NSString * const NBClientCapitalAmountInCentsKey;
extern NSString * const NBClientCapitalUserContentKey;

// The client works with the NationBuilder API. It is an API client. For
// authentication, it relies on its authenticator or test token. Conventionally,
// its methods directly match the API endpoints, but are named according to its
// own, more native-based conventions. Each method takes a completion handler
// which handles both success and error case. The type is conventionally defined to
// be either `NBClientResourceListCompletionHandler` or
// `NBClientResourceItemCompletionHandler`.
@interface NBClient : NSObject <NSURLSessionDataDelegate, NBLogging>

@property (nonatomic, weak) id<NBClientDelegate> delegate;

@property (nonatomic, copy, readonly) NSString *nationSlug;
@property (nonatomic, readonly) NSURLSession *urlSession;
@property (nonatomic, readonly) NSURLSessionConfiguration *sessionConfiguration;

@property (nonatomic, readonly) NBAuthenticator *authenticator;

@property (nonatomic, readonly) NSURL *baseURL;

@property (nonatomic, copy) NSString *apiKey; // Set this upon successful authentication.
@property (nonatomic, copy) NSString *apiVersion; // Optional. For future use.

@property (nonatomic) BOOL shouldUseLegacyPagination; // Set this to true if absolutely necessary.

// The main initializer.
- (instancetype)initWithNationSlug:(NSString *)nationSlug
                     authenticator:(NBAuthenticator *)authenticator
                  customURLSession:(NSURLSession *)urlSession
     customURLSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration;

// The alternate initializer for developing using pre-generated API tokens.
// Using this approach is discouraged unless you're confident about how securely
// you are storing the token.
// Note the main initializer doesn't accept a custom base-URL because it should
// be already set on the authenticator.
- (instancetype)initWithNationSlug:(NSString *)nationSlug
                            apiKey:(NSString *)apiKey
                     customBaseURL:(NSURL *)baseURL
                  customURLSession:(NSURLSession *)urlSession
     customURLSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration;

@end

// Implement this protocol to customize the general response and request
// handling for a client, ie. do something before each request gets sent or
// after each response gets received. Refer to the individual methods for more
// details.
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
