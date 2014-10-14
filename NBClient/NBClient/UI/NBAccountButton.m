//
//  NBAccountButton.m
//  NBClient
//
//  Created by Peng Wang on 10/7/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBAccountButton.h"

#import "QuartzCore/QuartzCore.h"

@interface NBAccountButton ()

@property (nonatomic, weak, readwrite) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak, readwrite) IBOutlet UIImageView *avatarImageView;

- (void)setUpSubviews;
- (void)tearDownSubviews;
- (void)updateSubviews;

@end

@implementation NBAccountButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpSubviews];
        [self updateSubviews];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    return self;
}
- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setUpSubviews];
    [self updateSubviews];
}
- (void)dealloc
{
    [self tearDownSubviews];
}

- (void)setUpSubviews
{
    self.avatarImageView.layer.cornerRadius = 2.0f;
}
- (void)tearDownSubviews
{
}
- (void)updateSubviews
{
    self.nameLabel.textColor = self.tintColor;
}

#pragma mark - UIControl

- (void)setHighlighted:(BOOL)highlighted
{
    super.highlighted = highlighted;
    [UIView animateWithDuration:self.highlightAnimationDuration.floatValue delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction
                     animations:^{ self.alpha = highlighted ? self.dimmedAlpha.floatValue : 1.0; }
                     completion:nil];
}

#pragma mark - UIView

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    [self updateSubviews];
}

@end
