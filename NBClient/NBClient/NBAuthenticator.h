//
//  NBAuthenticator.h
//  NBClient
//
//  Created by Peng Wang on 7/10/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NBAuthenticationCredential;

typedef void (^NBAuthenticationCompletionHandler)(NBAuthenticationCredential *credential, NSError *error);

extern NSUInteger const NBAuthenticationErrorCodeService;
extern NSUInteger const NBAuthenticationErrorCodeURLType;
extern NSUInteger const NBAuthenticationErrorCodeWebBrowser;
extern NSUInteger const NBAuthenticationErrorCodeKeychain;

extern NSString * const NBAuthenticationDefaultRedirectPath;

@interface NBAuthenticator : NSObject

@property (nonatomic, strong, readonly) NSURL *baseURL;
@property (nonatomic, strong, readonly) NSString *clientIdentifier;
@property (nonatomic, strong, readonly) NSString *credentialIdentifier;
@property (nonatomic, strong, readonly) NBAuthenticationCredential *credential;
@property (nonatomic, readonly, getter = isAuthenticatingInWebBrowser) BOOL authenticatingInWebBrowser;

@property (nonatomic) BOOL shouldAutomaticallySaveCredential;

// Designated initializer.
- (instancetype)initWithBaseURL:(NSURL *)baseURL
               clientIdentifier:(NSString *)clientIdentifier;

/**
 Authentication API
 
 @note Completion handlers may be dispatched synchronously. Async should not be assumed.
 */

- (void)authenticateWithRedirectPath:(NSString *)redirectPath
                   completionHandler:(NBAuthenticationCompletionHandler)completionHandler;

- (NSURLSessionDataTask *)authenticateWithUserName:(NSString *)userName
                                          password:(NSString *)password
                                      clientSecret:(NSString *)clientSecret
                                 completionHandler:(NBAuthenticationCompletionHandler)completionHandler;

- (BOOL)discardCredential;

+ (NSString *)authorizationRedirectApplicationURLScheme;
+ (BOOL)finishAuthenticatingInWebBrowserWithURL:(NSURL *)url error:(NSError **)error;

@end

@interface NBAuthenticationCredential : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSString *accessToken;
@property (nonatomic, strong, readonly) NSString *tokenType;

// Designated initializer.
- (instancetype)initWithAccessToken:(NSString *)accessToken
                          tokenType:(NSString *)tokenTypeOrNil;

+ (BOOL)saveCredential:(NBAuthenticationCredential *)credential
        withIdentifier:(NSString *)identifier;
+ (BOOL)deleteCredentialWithIdentifier:(NSString *)identifier;
+ (NBAuthenticationCredential *)fetchCredentialWithIdentifier:(NSString *)identifier;

@end
