//
//  NBAuthenticator_Internal.h
//  NBClient
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBAuthenticator.h"

@interface NBAuthenticator ()

@property (nonatomic, readwrite) NSURL *baseURL;
@property (nonatomic, readwrite) NSString *clientIdentifier;
@property (nonatomic, readwrite) NBAuthenticationCredential *credential;

// #token-flow
@property (nonatomic, strong) NBAuthenticationCompletionHandler currentInBrowserAuthenticationCompletionHandler;
@property (nonatomic) BOOL currentlyNeedsPriorSignout;

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

@property (nonatomic, copy, readwrite) NSString *accessToken;
@property (nonatomic, copy, readwrite) NSString *tokenType;

+ (NSMutableDictionary *)baseKeychainQueryDictionaryWithIdentifier:(NSString *)identifier;

@end
