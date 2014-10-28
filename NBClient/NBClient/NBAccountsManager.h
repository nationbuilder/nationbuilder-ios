//
//  NBAccountsManager.h
//  NBClient
//
//  Created by Peng Wang on 10/9/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NBAccountsViewDefines.h"
#import "NBDefines.h"

@class NBAccount;

@interface NBAccountsManager : NSObject <NBAccountsViewDataSource, NBLogging>

@property (nonatomic, weak, readonly) id<NBAccountsManagerDelegate> delegate;

- (instancetype)initWithClientInfo:(NSDictionary *)clientInfoOrNil
                          delegate:(id<NBAccountsManagerDelegate>)delegate;

@end