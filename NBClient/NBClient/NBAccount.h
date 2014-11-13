//
//  NBAccount.h
//  NBClient
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NBAccountsViewDefines.h"
#import "NBDefines.h"

#import "NBClient.h"

@class NBAuthenticator;

@protocol NBAccountDelegate;

// The account model builds upon the client and authenticator objects. It provides
// a simpler interface than manually managing a client and an authenticator. It can
// become the data source for views including the account button.
@interface NBAccount : NSObject <NBAccountViewDataSource, NBClientDelegate, NBLogging>

@property (nonatomic, weak, readonly) id<NBAccountDelegate> delegate;

@property (nonatomic, strong, readonly) NBClient *client;
@property (nonatomic, strong, readonly) NBAuthenticator *authenticator;

@property (nonatomic, strong, readonly) NSDictionary *clientInfo;
// Will load from the conventional plist with name equal to NBInfoFileName. Useful if your app is only for one nation.
@property (nonatomic, strong, readonly) NSDictionary *defaultClientInfo;

@property (nonatomic) NSUInteger identifier;
@property (nonatomic, strong) NSString *name; // Override.

@property (nonatomic, getter = isActive) BOOL active;
@property (nonatomic) BOOL shouldUseTestToken;

- (instancetype)initWithClientInfo:(NSDictionary *)clientInfoOrNil
                          delegate:(id<NBAccountDelegate>)delegate;

- (void)requestActiveWithPriorSignout:(BOOL)needsPriorSignout
                    completionHandler:(NBGenericCompletionHandler)completionHandler;

- (BOOL)requestCleanUpWithError:(NSError **)error;

@end

@protocol NBAccountDelegate <NSObject>

- (void)account:(NBAccount *)account didBecomeInvalidFromHTTPError:(NSError *)error;

@end
