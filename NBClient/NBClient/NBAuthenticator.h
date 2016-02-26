//
//  NBAuthenticator.h
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NBDefines.h"

@class NBAuthenticationCredential;

typedef void (^NBAuthenticationCompletionHandler)(NBAuthenticationCredential * __nullable credential, NSError * __nullable error);

extern NSInteger const NBAuthenticationErrorCodeService;
extern NSInteger const NBAuthenticationErrorCodeURLType;
extern NSInteger const NBAuthenticationErrorCodeWebBrowser;
extern NSInteger const NBAuthenticationErrorCodeKeychain;
extern NSInteger const NBAuthenticationErrorCodeUser;

extern NSString * __nonnull const NBAuthenticationDefaultRedirectPath;

// The authenticator encapsulates the basic features of an OAuth 2 client. The
// OAuth flows currently provided are the token and password flows. The token flow
// is the suggested approach and is implemented by methods and properties with the
// `#token-flow` tag comment. The password-grant-type flow is discouraged and
// only intended if your app is to be used by only your own nation.
@interface NBAuthenticator : NSObject <NBLogging>

@property (nonatomic, readonly, nonnull) NSURL *baseURL;
@property (nonatomic, copy, readonly, nonnull) NSString *clientIdentifier;
@property (nonatomic, readonly, nullable) NBAuthenticationCredential *credential;
// #token-flow
@property (nonatomic, readonly, getter = isAuthenticatingInWebBrowser) BOOL authenticatingInWebBrowser;

@property (nonatomic, copy, nonnull) NSString *credentialIdentifier;
@property (nonatomic, copy, readonly, nonnull) NSString *defaultCredentialIdentifier;
@property (nonatomic) BOOL shouldPersistCredential;

// Designated initializer.
- (nonnull instancetype)initWithBaseURL:(nonnull NSURL *)baseURL
                       clientIdentifier:(nonnull NSString *)clientIdentifier;

// NOTE: Completion handlers may be dispatched synchronously. Async should not be assumed.

// #token-flow
- (void)authenticateWithRedirectPath:(nonnull NSString *)redirectPath
                        priorSignout:(BOOL)needsPriorSignout
                   completionHandler:(nonnull NBAuthenticationCompletionHandler)completionHandler;
// Use these methods if you are performing the authorization in your own
// WKWebView and need to manually store and access token flow data.
- (void)setCredentialWithAccessToken:(nonnull NSString *)accessToken
                           tokenType:(nullable NSString *)tokenTypeOrNil;
- (nullable NSURL *)authenticationURLWithRedirectPath:(nonnull NSString *)redirectPath;

- (nullable NSURLSessionDataTask *)authenticateWithUserName:(nonnull NSString *)userName
                                                   password:(nonnull NSString *)password
                                               clientSecret:(nonnull NSString *)clientSecret
                                          completionHandler:(nonnull NBAuthenticationCompletionHandler)completionHandler;

- (BOOL)discardCredential;

// #token-flow
+ (nullable NSString *)authorizationRedirectApplicationURLScheme;
+ (BOOL)finishAuthenticatingInWebBrowserWithURL:(nonnull NSURL *)url;

@end

// The authentication credential objectifies the access token and provides
// static methods for securely managing the credential on the user's keychain.
@interface NBAuthenticationCredential : NSObject <NSCoding>

@property (nonatomic, copy, readonly, nonnull) NSString *accessToken;
@property (nonatomic, copy, readonly, nullable) NSString *tokenType;

// Designated initializer.
- (nonnull instancetype)initWithAccessToken:(nonnull NSString *)accessToken
                                  tokenType:(nullable NSString *)tokenTypeOrNil;

+ (BOOL)saveCredential:(nullable NBAuthenticationCredential *)credential
        withIdentifier:(nonnull NSString *)identifier;
+ (BOOL)deleteCredentialWithIdentifier:(nonnull NSString *)identifier;
+ (nullable NBAuthenticationCredential *)fetchCredentialWithIdentifier:(nonnull NSString *)identifier;

@end
