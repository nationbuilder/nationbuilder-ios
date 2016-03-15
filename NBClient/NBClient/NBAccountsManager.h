//
//  NBAccountsManager.h
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import <Foundation/Foundation.h>

#import "NBAccountsViewDefines.h"
#import "NBDefines.h"

#import "NBAccount.h"

// The account manager builds on top of the account model, and unlike the lower
// level classes, it relies on delegation to integrate with other classes, ie. the
// app delegate. It provides a simpler interface than manually managing one or more
// accounts. It can become the data source for the accounts view controller.
@interface NBAccountsManager : NSObject <NBAccountsViewDataSource, NBAccountDelegate, NBLogging>

@property (nonatomic, weak, readonly, nullable) id<NBAccountsManagerDelegate> delegate;
@property (nonatomic, readonly) BOOL shouldPersistAccounts;

- (nonnull instancetype)initWithClientInfo:(nullable NSDictionary *)clientInfoOrNil
                                  delegate:(nonnull id<NBAccountsManagerDelegate>)delegate;

@end
