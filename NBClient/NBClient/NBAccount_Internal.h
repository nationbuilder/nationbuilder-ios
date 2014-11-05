//
//  NBAccount_Internal.h
//  NBClient
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBAccount.h"

@interface NBAccount ()

@property (nonatomic, weak, readwrite) id<NBAccountDelegate> delegate;
@property (nonatomic, strong, readwrite) NBClient *client;
@property (nonatomic, strong, readwrite) NSDictionary *clientInfo;
@property (nonatomic, strong, readwrite) NSDictionary *defaultClientInfo;

@property (nonatomic, strong) NBAuthenticator *authenticator;

@property (nonatomic, strong) NSDictionary *person;

- (NSURL *)baseURL;

- (void)fetchPersonWithCompletionHandler:(NBGenericCompletionHandler)completionHandler;
- (void)fetchAvatarWithCompletionHandler:(NBGenericCompletionHandler)completionHandler;

- (void)updateCredentialIdentifier;

@end
