//
//  NBAccountButton.h
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
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

@property (nonatomic, weak, nullable) id<NBAccountViewDataSource> dataSource;
// Set this to reference your NBAccountManager if you are using one.
@property (nonatomic, weak, nullable) id<NBAccountsViewDataSource> dataSources;

@property (nonatomic, weak, readonly, nullable) UILabel *nameLabel;
@property (nonatomic, weak, readonly, nullable) UIImageView *avatarImageView;

@property (nonatomic) NBAccountButtonType buttonType UI_APPEARANCE_SELECTOR;
@property (nonatomic) BOOL shouldUseCircleAvatarFrame UI_APPEARANCE_SELECTOR;

@property (nonatomic, nullable) NSNumber *cornerRadius UI_APPEARANCE_SELECTOR;
@property (nonatomic, nullable) NSNumber *dimmedAlpha UI_APPEARANCE_SELECTOR;
@property (nonatomic, nullable) NSNumber *highlightAnimationDuration UI_APPEARANCE_SELECTOR;

// Use `-barButtonItemWithCompactButtonType:` to get the initial button item.
@property (nonatomic, readonly, nullable) UIBarButtonItem *barButtonItem;

// This is a convenience factory method.
+ (nonnull NBAccountButton *)accountButtonFromNibWithTarget:(nonnull id)target action:(nonnull SEL)action;

// Access this to get a dedicated button item for your account button. It will
// also let the button know it's being used as the custom view for a button item.
- (nonnull UIBarButtonItem *)barButtonItemWithCompactButtonType:(NBAccountButtonType)compactButtonType;

@end
