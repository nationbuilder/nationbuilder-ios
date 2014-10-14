//
//  NBAccountButton.h
//  NBClient
//
//  Created by Peng Wang on 10/7/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NBAccountButton : UIControl

@property (nonatomic, weak, readonly) UILabel *nameLabel;
@property (nonatomic, weak, readonly) UIImageView *avatarImageView;

@property (nonatomic, strong) NSNumber *dimmedAlpha UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) NSNumber *highlightAnimationDuration UI_APPEARANCE_SELECTOR;

@end
