//
//  NBAccountsManager.h
//  NBClient
//
//  Created by Peng Wang on 10/9/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NBAccountsViewDefines.h"

@class NBAccount;

@interface NBAccountsManager : NSObject <NBAccountsViewDataSource>

@property (nonatomic, weak) id<NBAccountsManagerDelegate> delegate;

@property (nonatomic) BOOL shouldPersistAccounts;

- (instancetype)initWithClientInfo:(NSDictionary *)clientInfoOrNil;

@end