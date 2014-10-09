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

/**
 OAuth 2.0 provides several grant types, covering several different use cases. The following
 grant type string constants are provided:
 
 `NBAuthenticationGrantTypeCode`: "authorization_code"
 `NBAuthenticationGrantTypeClientCredential`: "client_credentials"
 `NBAuthenticationGrantTypePasswordCredential`: "password"
 `NBAuthenticationGrantTypeRefresh`: "refresh_token"
 */
extern NSString * const NBAuthenticationGrantTypeCode; // (NOTE: Not implemented.)
extern NSString * const NBAuthenticationGrantTypeClientCredential; // (NOTE: Not implemented.)
extern NSString * const NBAuthenticationGrantTypePasswordCredential;
extern NSString * const NBAuthenticationGrantTypeRefresh; // (NOTE: Not implemented.)

extern NSUInteger const NBAuthenticationErrorCodeService;

extern NSString * const NBAuthenticationRedirectTokenKey;

@interface NBAuthenticator : NSObject

@property (nonatomic, strong, readonly) NSURL *baseURL;
@property (nonatomic, strong, readonly) NSString *clientIdentifier;
@property (nonatomic, strong, readonly) NSString *credentialIdentifier;

@property (nonatomic) BOOL shouldAutomaticallySaveCredential;

// Designated initializer.
- (instancetype)initWithBaseURL:(NSURL *)baseURL
               clientIdentifier:(NSString *)clientIdentifier
                   clientSecret:(NSString *)clientSecret;

/**
 Authentication API
 
 @note Completion handlers may be dispatched synchronously. Async should not be assumed.
 */

- (NSURLSessionDataTask *)authenticateWithUserName:(NSString *)userName
                                          password:(NSString *)password
                                 completionHandler:(NBAuthenticationCompletionHandler)completionHandler;

- (NSURLSessionDataTask *)authenticateWithSubPath:(NSString *)subPath
                                       parameters:(NSDictionary *)parameters
                                completionHandler:(NBAuthenticationCompletionHandler)completionHandler;

@end

@interface NBAuthenticationCredential : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSString *accessToken;
@property (nonatomic, strong, readonly) NSString *tokenType;

// Designated initializer.
- (instancetype)initWithAccessToken:(NSString *)accessToken
                          tokenType:(NSString *)tokenType;

+ (BOOL)saveCredential:(NBAuthenticationCredential *)credential
        withIdentifier:(NSString *)identifier;
+ (BOOL)deleteCredentialWithIdentifier:(NSString *)identifier;
+ (NBAuthenticationCredential *)fetchCredentialWithIdentifier:(NSString *)identifier;

@end
