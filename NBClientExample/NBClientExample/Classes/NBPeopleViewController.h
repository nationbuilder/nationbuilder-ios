//
//  NBPeopleViewController.h
//  NBClientExample
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NBUIDefines.h"

@class NBAccountButton;

@interface NBPeopleViewController : UICollectionViewController <NBViewController>

@property (nonatomic, getter = isReady) BOOL ready;
@property (nonatomic, readonly) UILabel *notReadyLabel;

- (void)showAccountButton:(NBAccountButton *)accountButton;

@end