//
//  NBAccountButton.h
//  NBClient
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, NBAccountButtonType) {
    NBAccountButtonTypeDefault,
    NBAccountButtonTypeAvatarOnly,
    NBAccountButtonTypeIconOnly,
    NBAccountButtonTypeNameOnly,
};

@protocol NBAccountViewDataSource;

@interface NBAccountButton : UIControl

@property (nonatomic, weak) id<NBAccountViewDataSource> dataSource;

@property (nonatomic, weak, readonly) UILabel *nameLabel;
@property (nonatomic, weak, readonly) UIImageView *avatarImageView;

@property (nonatomic) NBAccountButtonType buttonType UI_APPEARANCE_SELECTOR;
@property (nonatomic) BOOL shouldUseCircleAvatarFrame UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) NSNumber *cornerRadius UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) NSNumber *dimmedAlpha UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) NSNumber *highlightAnimationDuration UI_APPEARANCE_SELECTOR;

// Access this to get a dedicated button item for your account button. It will
// also let the button know it's being used as the custom view for a button item.
@property (nonatomic, strong) UIBarButtonItem *barButtonItem;

@property (nonatomic) BOOL contextHasMultipleActiveAccounts;

// This is a convenience factory method.
+ (NBAccountButton *)accountButtonFromNibWithTarget:(id)target action:(SEL)action;

@end
