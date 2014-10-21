//
//  NBAccountButton.m
//  NBClient
//
//  Created by Peng Wang on 10/7/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBAccountButton.h"

#import "QuartzCore/QuartzCore.h"

#import "FoundationAdditions.h"
#import "NBAccountsViewDefines.h"

static NSString *HiddenKeyPath = @"hidden";

static void *observationContext = &observationContext;

@interface NBAccountButton ()

@property (nonatomic, weak, readwrite) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak, readwrite) IBOutlet UIImageView *avatarImageView;

// For avatar hiding.
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *avatarImageWidth;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *avatarImageMarginRight;
@property (nonatomic) CGFloat originalAvatarImageWidth;
@property (nonatomic) CGFloat originalAvatarImageMarginRight;

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
        self.dataSource = nil;
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
    self.dataSource = nil;
}
- (void)dealloc
{
    [self tearDownSubviews];
}

- (void)setUpSubviews
{
    self.avatarImageView.layer.cornerRadius = 2.0f;
    // Set up avatar hiding.
    [self.avatarImageView addObserver:self forKeyPath:HiddenKeyPath options:0 context:&observationContext];
    self.originalAvatarImageWidth = self.avatarImageWidth.constant;
    self.originalAvatarImageMarginRight = self.avatarImageMarginRight.constant;
}
- (void)tearDownSubviews
{
    [self.avatarImageView removeObserver:self forKeyPath:HiddenKeyPath context:&observationContext];
}
- (void)updateSubviews
{
    self.nameLabel.textColor = self.tintColor;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != &observationContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if ([keyPath isEqual:HiddenKeyPath]) {
        // Toggle avatar hiding.
        self.avatarImageWidth.constant = self.avatarImageView.isHidden ? 0.0f : self.originalAvatarImageWidth;
        self.avatarImageMarginRight.constant = self.avatarImageView.isHidden ? 0.0f : self.originalAvatarImageMarginRight;
        [self setNeedsUpdateConstraints];
    }
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

#pragma mark - Public

#pragma mark Accessors

- (void)setDataSource:(id<NBAccountViewDataSource>)dataSource
{
    // Boilerplate.
    static NSString *key;
    key = key ?: NSStringFromSelector(@selector(dataSource));
    [self willChangeValueForKey:key];
    _dataSource = dataSource;
    [self didChangeValueForKey:key];
    // END: Boilerplate.
    if (dataSource) {
        self.nameLabel.text = dataSource.name;
        self.avatarImageView.image = [UIImage imageWithData:dataSource.avatarImageData];
    } else {
        self.nameLabel.text = @"label.sign-in".nb_localizedString;
    }
}

@end
