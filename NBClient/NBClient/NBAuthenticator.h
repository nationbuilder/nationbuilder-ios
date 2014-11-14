//
//  NBAuthenticator.h
//  NBClient
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NBDefines.h"

@class NBAuthenticationCredential;

typedef void (^NBAuthenticationCompletionHandler)(NBAuthenticationCredential *credential, NSError *error);

extern NSInteger const NBAuthenticationErrorCodeService;
extern NSInteger const NBAuthenticationErrorCodeURLType;
extern NSInteger const NBAuthenticationErrorCodeWebBrowser;
extern NSInteger const NBAuthenticationErrorCodeKeychain;

extern NSString * const NBAuthenticationDefaultRedirectPath;

// The authenticator encapsulates the basic features of an OAuth 2 client. The
// OAuth flows currently provided are the token and password flows. The token flow
// is the suggested approach and is implemented by methods and properties with the
// `#token-flow` tag comment. The password-grant-type flow is discouraged and
// only intended if your app is to be used by only your own nation.
@interface NBAuthenticator : NSObject <NBLogging>

@property (nonatomic, readonly) NSURL *baseURL;
@property (nonatomic, readonly) NSString *clientIdentifier;
@property (nonatomic, readonly) NBAuthenticationCredential *credential;
// #token-flow
@property (nonatomic, readonly, getter = isAuthenticatingInWebBrowser) BOOL authenticatingInWebBrowser;

@property (nonatomic) NSString *credentialIdentifier;
@property (nonatomic) BOOL shouldPersistCredential;

// Designated initializer.
- (instancetype)initWithBaseURL:(NSURL *)baseURL
               clientIdentifier:(NSString *)clientIdentifier;

// NOTE: Completion handlers may be dispatched synchronously. Async should not be assumed.

// #token-flow
- (void)authenticateWithRedirectPath:(NSString *)redirectPath
                        priorSignout:(BOOL)needsPriorSignout
                   completionHandler:(NBAuthenticationCompletionHandler)completionHandler;

- (NSURLSessionDataTask *)authenticateWithUserName:(NSString *)userName
                                          password:(NSString *)password
                                      clientSecret:(NSString *)clientSecret
                                 completionHandler:(NBAuthenticationCompletionHandler)completionHandler;

- (BOOL)discardCredential;

// #token-flow
+ (NSString *)authorizationRedirectApplicationURLScheme;
+ (BOOL)finishAuthenticatingInWebBrowserWithURL:(NSURL *)url error:(NSError **)error;

@end

// The authentication credential objectifies the access token and provides
// static methods for securely managing the credential on the user's keychain.
@interface NBAuthenticationCredential : NSObject <NSCoding>

@property (nonatomic, readonly) NSString *accessToken;
@property (nonatomic, readonly) NSString *tokenType;

// Designated initializer.
- (instancetype)initWithAccessToken:(NSString *)accessToken
                          tokenType:(NSString *)tokenTypeOrNil;

+ (BOOL)saveCredential:(NBAuthenticationCredential *)credential
        withIdentifier:(NSString *)identifier;
+ (BOOL)deleteCredentialWithIdentifier:(NSString *)identifier;
+ (NBAuthenticationCredential *)fetchCredentialWithIdentifier:(NSString *)identifier;

@end
