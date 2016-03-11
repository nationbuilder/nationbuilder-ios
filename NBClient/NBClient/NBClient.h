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

typedef void (^NBClientResourceListCompletionHandler)(NSArray * __nullable items, NBPaginationInfo * __nullable paginationInfo, NSError * __nullable error);
typedef void (^NBClientResourceItemCompletionHandler)(NSDictionary * __nullable item, NSError * __nullable error);
// Sometimes the API will return non-RESTful resources, ie. people/count.
typedef void (^NBClientResourceCompletionHandler)(id __nullable result, NSError * __nullable error);

// Use these constants when working with the client's errors.
extern NSUInteger const NBClientErrorCodeService;
extern NSString * __nonnull const NBClientErrorCodeKey;
extern NSString * __nonnull const NBClientErrorHTTPStatusCodeKey;
extern NSString * __nonnull const NBClientErrorMessageKey;
extern NSString * __nonnull const NBClientErrorValidationErrorsKey;
extern NSString * __nonnull const NBClientErrorInnerErrorKey;

// You can also get the default values for some properties.
extern NSString * __nonnull const NBClientDefaultAPIVersion;
extern NSString * __nonnull const NBClientDefaultBaseURLFormat;

extern NSString * __nonnull const NBClientPaginationTokenOptInKey;

// NOTE: With the exception of the person resource, convenient key constants are
//       provided for request payload property names.
extern NSString * __nonnull const NBClientLocationLatitudeKey;
extern NSString * __nonnull const NBClientLocationLongitudeKey;
extern NSString * __nonnull const NBClientLocationProximityDistanceKey; // Integer, radius in miles.

extern NSString * __nonnull const NBClientTaggingTagNameOrListKey; // String or array for bulk operations.

extern NSString * __nonnull const NBClientCapitalAmountInCentsKey;
extern NSString * __nonnull const NBClientCapitalUserContentKey;

extern NSString * __nonnull const NBClientContactBroadcasterIdentifierKey;
extern NSString * __nonnull const NBClientContactMethodKey;
extern NSString * __nonnull const NBClientContactNoteKey;
extern NSString * __nonnull const NBClientContactSenderIdentifierKey;
extern NSString * __nonnull const NBClientContactStatusKey;
extern NSString * __nonnull const NBClientContactTypeIdentifierKey;

extern NSString * __nonnull const NBClientDonationAmountInCentsKey;
extern NSString * __nonnull const NBClientDonationDonorIdentifierKey;
extern NSString * __nonnull const NBClientDonationPaymentTypeNameKey;

// The client works with the NationBuilder API. It is an API client. For
// authentication, it relies on its authenticator or test token. Conventionally,
// its methods directly match the API endpoints, but are named according to its
// own, more native-based conventions. Each method takes a completion handler
// which handles both success and error case. The type is conventionally defined to
// be either `NBClientResourceListCompletionHandler` or
// `NBClientResourceItemCompletionHandler`.
@interface NBClient : NSObject <NSURLSessionDataDelegate, NBLogging>

@property (nonatomic, weak, nullable) id<NBClientDelegate> delegate;

@property (nonatomic, copy, readonly, nonnull) NSString *nationSlug;
@property (nonatomic, readonly, nonnull) NSURLSession *urlSession;
@property (nonatomic, readonly, nonnull) NSURLSessionConfiguration *sessionConfiguration;

@property (nonatomic, readonly, nullable) NBAuthenticator *authenticator;

@property (nonatomic, readonly, nonnull) NSURL *baseURL;

@property (nonatomic, copy, nullable) NSString *apiKey; // Set this upon successful authentication.
@property (nonatomic, copy, nonnull) NSString *apiVersion; // Optional. For future use.

@property (nonatomic) BOOL shouldUseLegacyPagination; // Set this to true if absolutely necessary.

// The main initializer.
- (nonnull instancetype)initWithNationSlug:(nonnull NSString *)nationSlug
                             authenticator:(nonnull NBAuthenticator *)authenticator
                          customURLSession:(nullable NSURLSession *)urlSession
             customURLSessionConfiguration:(nullable NSURLSessionConfiguration *)sessionConfiguration;

// The alternate initializer for developing using pre-generated API tokens.
// Using this approach is discouraged unless you're confident about how securely
// you are storing the token.
// Note the main initializer doesn't accept a custom base-URL because it should
// be already set on the authenticator.
- (nonnull instancetype)initWithNationSlug:(nonnull NSString *)nationSlug
                                    apiKey:(nonnull NSString *)apiKey
                             customBaseURL:(nullable NSURL *)baseURL
                          customURLSession:(nullable NSURLSession *)urlSession
             customURLSessionConfiguration:(nullable NSURLSessionConfiguration *)sessionConfiguration;

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
- (void)client:(nonnull NBClient *)client didParseJSON:(nullable NSDictionary *)jsonObject
                                          fromResponse:(nonnull NSHTTPURLResponse *)response
                                            forRequest:(nonnull NSURLRequest *)request;

// Useful for when you just want to create the data tasks but perhaps start them
// at a later time, and perhaps with more coordination, ie. with rate limits. By
// default, this method, if implemented, should return YES.
- (BOOL)client:(nonnull NBClient *)client shouldAutomaticallyStartDataTask:(nonnull NSURLSessionDataTask *)task;

// These 'shouldHandleResponse' methods allow you to halt default response
// handling at any error. For example, the accounts layer uses the 'HTTPError'
// variant to automatically sign out of the account that has the client.
// By default, these methods, if implemented, should return YES.
- (BOOL)client:(nonnull NBClient *)client shouldHandleResponse:(nonnull NSHTTPURLResponse *)response
                                                    forRequest:(nonnull NSURLRequest *)request;
- (BOOL)client:(nonnull NBClient *)client shouldHandleResponse:(nonnull NSHTTPURLResponse *)response
                                                    forRequest:(nonnull NSURLRequest *)request
                                             withDataTaskError:(nonnull NSError *)error;
// HTTP errors sometimes have additional values for the NBClientError* keys defined above.
- (BOOL)client:(nonnull NBClient *)client shouldHandleResponse:(nonnull NSHTTPURLResponse *)response
                                                    forRequest:(nonnull NSURLRequest *)request
                                                 withHTTPError:(nonnull NSError *)error;
// Service errors have additional values for the NBClientError* keys defined above.
- (BOOL)client:(nonnull NBClient *)client shouldHandleResponse:(nonnull NSHTTPURLResponse *)response
                                                    forRequest:(nonnull NSURLRequest *)request
                                              withServiceError:(nonnull NSError *)error;

// Useful for configuring any requests before they go out, ie. adding custom headers.
- (void)client:(nonnull NBClient *)client willCreateDataTaskForRequest:(nonnull NSMutableURLRequest *)request;

@end
