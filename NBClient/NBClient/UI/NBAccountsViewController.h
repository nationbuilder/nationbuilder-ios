//
//  NBAccountsViewController.h
//  NBClient
//
//  Created by Peng Wang on 10/9/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NBAccountsPickerView.h"
#import "NBAccountsViewDefines.h"

@interface NBAccountsViewController : UIViewController

@property (nonatomic, weak) id<NBAccountsViewDataSource> dataSource;

@property (nonatomic, strong, readonly) NBAccountsPickerView *pickerView;

@end

