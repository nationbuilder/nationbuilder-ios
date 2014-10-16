//
//  NBAccount.h
//  NBClient
//
//  Created by Peng Wang on 10/9/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NBDefines.h"
#import "NBAccountsViewDefines.h"

@class NBClient;
@class NBAuthenticator;

@interface NBAccount : NSObject <NBAccountViewDataSource>

@property (nonatomic, strong, readonly) NBClient *client;

// Will load from the conventional plist with name equal to NBInfoFileName. Useful if your app is only for one nation.
@property (nonatomic, strong, readonly) NSDictionary *defaultClientInfo;

@property (nonatomic, getter = isActive) BOOL active;
@property (nonatomic) BOOL shouldUseTestToken;

- (instancetype)initWithClientInfo:(NSDictionary *)clientInfoOrNil;

- (void)requestActiveWithCompletionHandler:(NBGenericCompletionHandler)completionHandler;

- (BOOL)requestCleanUpWithError:(NSError **)error;

@end