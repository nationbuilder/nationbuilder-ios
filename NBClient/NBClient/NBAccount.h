//
//  NBAccount.h
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
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

@property (nonatomic, weak, readonly, nullable) id<NBAccountDelegate> delegate;

@property (nonatomic, readonly, null_resettable) NBClient *client;
@property (nonatomic, readonly, nonnull) NBAuthenticator *authenticator;

@property (nonatomic, copy, readonly, nonnull) NSDictionary *clientInfo;
// Will load from the conventional plist with name equal to NBInfoFileName. Useful if your app is only for one nation.
@property (nonatomic, copy, readonly, nonnull) NSDictionary *defaultClientInfo;

@property (nonatomic) NSUInteger identifier;
@property (nonatomic, copy, nullable) NSString *name; // Override.

@property (nonatomic, getter = isActive) BOOL active;
@property (nonatomic) BOOL shouldUseTestToken;

- (nonnull instancetype)initWithClientInfo:(nullable NSDictionary *)clientInfoOrNil
                                  delegate:(nonnull id<NBAccountDelegate>)delegate;

- (void)requestActiveWithPriorSignout:(BOOL)needsPriorSignout
                    completionHandler:(nullable NBGenericCompletionHandler)completionHandler;

- (BOOL)requestCleanUpWithError:(NSError * __nullable * __nullable)error;

@end

@protocol NBAccountDelegate <NSObject>

- (void)account:(nonnull NBAccount *)account didBecomeInvalidFromHTTPError:(nonnull NSError *)error;

@end
