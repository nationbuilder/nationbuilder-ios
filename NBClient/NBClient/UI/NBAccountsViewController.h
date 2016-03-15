//
//  NBAccountsViewController.h
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import <UIKit/UIKit.h>

#import "NBAccountsViewDefines.h"
#import "NBDefines.h"

@class NBAccountButton;

@interface NBAccountsViewController : UIViewController <NBLogging>

@property (nonatomic, weak, nullable) id<NBAccountsViewDataSource> dataSource;

@property (nonatomic, weak, readonly, nullable) UIImageView *avatarImageView;
@property (nonatomic, weak, readonly, nullable) UILabel *nameLabel;
@property (nonatomic, weak, readonly, nullable) UILabel *nationLabel;
@property (nonatomic, weak, readonly, nullable) UIView *accountView;

@property (nonatomic, weak, readonly, nullable) UIButton *signOutButton;
@property (nonatomic, weak, readonly, nullable) UIButton *addAccountButton;

@property (nonatomic, weak, readonly, nullable) UIPickerView *accountsPicker;

@property (nonatomic, weak, readonly, nullable) UIImageView *logoImageView;

@property (nonatomic, nullable) UIColor *borderColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, nullable) NSNumber *cornerRadius UI_APPEARANCE_SELECTOR;

@property (nonatomic, nullable) UIColor *buttonBackgroundColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, nullable) UIColor *imageBorderColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, nullable) NSNumber *imageCornerRadius UI_APPEARANCE_SELECTOR;

@property (nonatomic, nullable) NSNumber *appearanceDuration UI_APPEARANCE_SELECTOR;

@property (nonatomic, getter = isPresentedInPopover) BOOL presentedInPopover;
@property (nonatomic) BOOL shouldAutoPromptForNationSlug;

// You can call this manually if you decide to turn off auto-prompting.
- (void)promptForNationSlug;

// This is a convenience method for showing the accounts view controller. Using
// this means being able to use the custom override of -dismissViewControllerAnimate:completion:.
// You may use it if you wish, but know that it's technically outside of the
// account view controller's responsibility to know how to present itself, and
// that your code should contain the presentation logic.
- (void)showWithAccountButton:(nonnull NBAccountButton *)accountButton
     presentingViewController:(nonnull UIViewController *)presentingViewController;

@end
