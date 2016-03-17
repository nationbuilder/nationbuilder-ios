//
//  NBAuthenticator_Internal.h
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBAuthenticator.h"

@class SFSafariViewController;

@interface NBAuthenticator ()

@property (nonatomic, readwrite, nonnull) NSURL *baseURL;
@property (nonatomic, readwrite, nonnull) NSString *clientIdentifier;
@property (nonatomic, readwrite, nullable) NBAuthenticationCredential *credential;

// #token-flow
@property (nonatomic, strong, nullable) NBAuthenticationCompletionHandler currentInBrowserAuthenticationCompletionHandler;
@property (nonatomic) BOOL currentlyNeedsPriorSignout;
@property (nonatomic) BOOL isObservingApplicationState;
@property (nonatomic, strong, nullable) SFSafariViewController *webBrowser;

- (nonnull NSDictionary *)authenticationParametersWithRedirectPath:(nonnull NSString *)redirectPath;
- (nullable NSURL *)authenticationURLWithSubPath:(nonnull NSString *)subPath
                                      parameters:(nonnull NSDictionary *)parameters;
- (nullable NSURLSessionDataTask *)authenticateWithSubPath:(nonnull NSString *)subPath
                                                parameters:(nonnull NSDictionary *)parameters
                                         completionHandler:(nonnull NBAuthenticationCompletionHandler)completionHandler;

// #token-flow
- (void)authenticateInWebBrowserWithURL:(nonnull NSURL *)url
                      completionHandler:(nonnull NBAuthenticationCompletionHandler)completionHandler;
- (void)finishAuthenticatingInWebBrowserWithNotification:(nonnull NSNotification *)notification;
- (void)openURLWithWebBrowser:(nonnull NSURL *)url;

- (nonnull NSURLSessionDataTask *)authenticationDataTaskWithURL:(nonnull NSURL *)url
                                              completionHandler:(nullable NBAuthenticationCompletionHandler)completionHandler;

@end

@interface NBAuthenticationCredential ()

@property (nonatomic, copy, readwrite, nonnull) NSString *accessToken;
@property (nonatomic, copy, readwrite, nullable) NSString *tokenType;

+ (nonnull NSMutableDictionary *)baseKeychainQueryDictionaryWithIdentifier:(nonnull NSString *)identifier;

@end
