//
//  NBAuthenticator.h
//  NBClient
//
//  Created by Peng Wang on 7/10/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NBAuthenticationCredentials;

typedef void (^NBAuthenticationCompletionHandler)(NBAuthenticationCredentials *credentials, NSError *error);

/**
 + OAuth 2.0 provides several grant types, covering several different use cases. The following
 + grant type string constants are provided:
 +
 + `NBAuthenticationGrantTypeCode`: "authorization_code"
 + `NBAuthenticationGrantTypeClientCredentials`: "client_credentials"
 + `NBAuthenticationGrantTypePasswordCredentials`: "password"
 + `NBAuthenticationGrantTypeRefresh`: "refresh_token"
 + */
extern NSString * const NBAuthenticationGrantTypeCode; // (NOTE: Not implemented.)
extern NSString * const NBAuthenticationGrantTypeClientCredentials; // (NOTE: Not implemented.)
extern NSString * const NBAuthenticationGrantTypePasswordCredentials;
extern NSString * const NBAuthenticationGrantTypeRefresh; // (NOTE: Not implemented.)

extern NSUInteger const NBAuthenticationErrorCodeService;

@interface NBAuthenticator : NSObject

@property (strong, nonatomic, readonly) NSURL *baseURL;
@property (strong, nonatomic, readonly) NSString *clientIdentifier;

- (instancetype)initWithBaseURL:(NSURL *)baseURL
               clientIdentifier:(NSString *)clientIdentifier
                   clientSecret:(NSString *)clientSecret;

- (NSURLSessionDataTask *)authenticateWithUserName:(NSString *)userName
                                          password:(NSString *)password
                                 completionHandler:(NBAuthenticationCompletionHandler)completionHandler;

- (NSURLSessionDataTask *)authenticateWithSubPath:(NSString *)subPath
                                       parameters:(NSDictionary *)parameters
                                completionHandler:(NBAuthenticationCompletionHandler)completionHandler;

@end

@interface NBAuthenticationCredentials : NSObject

@property (strong, nonatomic, readonly) NSString *accessToken;
@property (strong, nonatomic, readonly) NSString *tokenType;

@end
