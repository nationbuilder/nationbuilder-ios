//
//  NBAccountsViewDataSource.h
//  NBClient
//
//  Created by Peng Wang on 10/9/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NBAccount;
@class NBAccountsManager;

@protocol NBAccountsManagerDelegate <NSObject>

@optional

- (void)accountsManager:(NBAccountsManager *)accountsManager willSwitchFromAccount:(NBAccount *)account;
- (void)accountsManager:(NBAccountsManager *)accountsManager didSwitchToAccount:(NBAccount *)account;

@end

@protocol NBAccountsViewDataSource <NSObject>

@end

@protocol NBAccountsViewDelegate <NSObject>

@end