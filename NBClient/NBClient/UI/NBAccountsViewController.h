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
@property (nonatomic, weak) id<NBAccountsViewDelegate> delegate;

@property (nonatomic, weak, readonly) UIImageView *avatarImageView;
@property (nonatomic, weak, readonly) UILabel *nameLabel;
@property (nonatomic, weak, readonly) UILabel *nationLabel;
@property (nonatomic, weak, readonly) UIView *accountView;

@property (nonatomic, weak, readonly) UIButton *signOutButton;
@property (nonatomic, weak, readonly) UIButton *addAccountButton;

@property (nonatomic, strong) UIColor *borderColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) NSNumber *cornerRadius UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) UIColor *buttonBackgroundColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) UIColor *imageBorderColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) NSNumber *imageCornerRadius UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) NSNumber *appearanceDuration UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong, readonly) NBAccountsPickerView *pickerView;

@property (nonatomic) BOOL shouldAutoPromptForNationSlug;

- (void)promptForNationSlug;

@end
