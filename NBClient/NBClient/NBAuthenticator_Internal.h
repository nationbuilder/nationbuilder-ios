//
//  NBAuthenticator_Internal.h
//  NBClient
//
//  Created by Peng Wang on 11/3/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBAuthenticator.h"

@interface NBAuthenticator ()

@property (nonatomic, strong, readwrite) NSURL *baseURL;
@property (nonatomic, strong, readwrite) NSString *clientIdentifier;
@property (nonatomic, strong, readwrite) NBAuthenticationCredential *credential;

// #token-flow
@property (nonatomic, strong) NBAuthenticationCompletionHandler currentInBrowserAuthenticationCompletionHandler;
@property (nonatomic) BOOL currentlyNeedsPriorSignout;

@property (nonatomic, getter = isTesting) BOOL testing;

- (NSURLSessionDataTask *)authenticateWithSubPath:(NSString *)subPath
                                       parameters:(NSDictionary *)parameters
                                completionHandler:(NBAuthenticationCompletionHandler)completionHandler;

// #token-flow
- (void)authenticateInWebBrowserWithURL:(NSURL *)url
                      completionHandler:(NBAuthenticationCompletionHandler)completionHandler;
- (void)finishAuthenticatingInWebBrowserWithNotification:(NSNotification *)notification;

- (NSURLSessionDataTask *)authenticationDataTaskWithURL:(NSURL *)url
                                      completionHandler:(NBAuthenticationCompletionHandler)completionHandler;

@end

@interface NBAuthenticationCredential ()

@property (nonatomic, strong, readwrite) NSString *accessToken;
@property (nonatomic, strong, readwrite) NSString *tokenType;

+ (NSMutableDictionary *)baseKeychainQueryDictionaryWithIdentifier:(NSString *)identifier;

@end