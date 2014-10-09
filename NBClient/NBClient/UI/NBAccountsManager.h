//
//  NBAccountsManager.h
//  NBClient
//
//  Created by Peng Wang on 10/9/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NBAccountsViewDefines.h"

@interface NBAccountsManager : NSObject <NBAccountsViewDataSource>

@end

@protocol NBAccountsManagerDelegate <NSObject>

@end