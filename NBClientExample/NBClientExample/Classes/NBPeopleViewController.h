//
//  NBPeopleViewController.h
//  NBClientExample
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import <UIKit/UIKit.h>

#import "NBUIDefines.h"

@class NBAccountButton;

@interface NBPeopleViewController : UICollectionViewController <NBViewController>

@property (nonatomic, getter = isReady) BOOL ready;
@property (nonatomic, readonly) UILabel *notReadyLabel;

- (void)showAccountButton:(NBAccountButton *)accountButton;

@end