//
//  NBAccountButton.h
//  NBClient
//
//  Created by Peng Wang on 10/7/14.
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

@property (nonatomic) BOOL contextHasMultipleActiveAccounts;

@end
