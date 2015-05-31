//
//  NBAccount_Internal.h
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import "NBAccount.h"

@interface NBAccount ()

@property (nonatomic, weak, readwrite, nullable) id<NBAccountDelegate> delegate;

@property (nonatomic, readwrite, null_resettable) NBClient *client;
@property (nonatomic, readwrite, nonnull) NBAuthenticator *authenticator;

@property (nonatomic, copy, readwrite, nonnull) NSDictionary *clientInfo;
@property (nonatomic, copy, readwrite, nonnull) NSDictionary *defaultClientInfo;

@property (nonatomic, copy, nullable) NSDictionary *person;

- (nonnull NSURL *)baseURL;

- (void)fetchPersonWithCompletionHandler:(nullable NBGenericCompletionHandler)completionHandler;
- (void)fetchAvatarWithCompletionHandler:(nullable NBGenericCompletionHandler)completionHandler;

- (BOOL)updateCredentialIdentifier;

@end
