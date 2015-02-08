//
//  NBAccountButton.h
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, NBAccountButtonType) {
    NBAccountButtonTypeDefault,
    NBAccountButtonTypeAvatarOnly,
    NBAccountButtonTypeIconOnly,
    NBAccountButtonTypeNameOnly,
};

@protocol NBAccountViewDataSource;
@protocol NBAccountsViewDataSource;

@interface NBAccountButton : UIControl

@property (nonatomic, weak) id<NBAccountViewDataSource> dataSource;
// Set this to reference your NBAccountManager if you are using one.
@property (nonatomic, weak) id<NBAccountsViewDataSource> dataSources;

@property (nonatomic, weak, readonly) UILabel *nameLabel;
@property (nonatomic, weak, readonly) UIImageView *avatarImageView;

@property (nonatomic) NBAccountButtonType buttonType UI_APPEARANCE_SELECTOR;
@property (nonatomic) BOOL shouldUseCircleAvatarFrame UI_APPEARANCE_SELECTOR;

@property (nonatomic) NSNumber *cornerRadius UI_APPEARANCE_SELECTOR;
@property (nonatomic) NSNumber *dimmedAlpha UI_APPEARANCE_SELECTOR;
@property (nonatomic) NSNumber *highlightAnimationDuration UI_APPEARANCE_SELECTOR;

// Use `-barButtonItemWithCompactButtonType:` to get the initial button item.
@property (nonatomic, readonly) UIBarButtonItem *barButtonItem;

// This is a convenience factory method.
+ (NBAccountButton *)accountButtonFromNibWithTarget:(id)target action:(SEL)action;

// Access this to get a dedicated button item for your account button. It will
// also let the button know it's being used as the custom view for a button item.
- (UIBarButtonItem *)barButtonItemWithCompactButtonType:(NBAccountButtonType)compactButtonType;

@end
