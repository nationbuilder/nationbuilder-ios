//
//  NBAccount_Internal.h
//  NBClient
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBAccount.h"

@interface NBAccount ()

@property (nonatomic, weak, readwrite) id<NBAccountDelegate> delegate;
@property (nonatomic, readwrite) NBClient *client;
@property (nonatomic, copy, readwrite) NSDictionary *clientInfo;
@property (nonatomic, copy, readwrite) NSDictionary *defaultClientInfo;

@property (nonatomic) NBAuthenticator *authenticator;

@property (nonatomic, copy) NSDictionary *person;

- (NSURL *)baseURL;

- (void)fetchPersonWithCompletionHandler:(NBGenericCompletionHandler)completionHandler;
- (void)fetchAvatarWithCompletionHandler:(NBGenericCompletionHandler)completionHandler;

- (void)updateCredentialIdentifier;

@end
