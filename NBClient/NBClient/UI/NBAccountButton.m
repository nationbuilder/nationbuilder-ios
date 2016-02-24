//
//  NBAccountButton.m
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import "NBAccountButton.h"

#import "QuartzCore/QuartzCore.h"

#import "FoundationAdditions.h"
#import "NBAccountsViewDefines.h"
#import "NBDefines.h"

static NSString *HiddenKeyPath;
static NSString *SelectedAccountKeyPath;

static void *observationContext = &observationContext;

@interface NBAccountButton ()

@property (nonatomic, weak, readwrite) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak, readwrite) IBOutlet UIImageView *avatarImageView;

@property (nonatomic, readwrite) UIBarButtonItem *barButtonItem;

@property (nonatomic) NBAccountButtonType actualButtonType;

// For avatar hiding.
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *avatarImageWidth;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *avatarImageMarginRight;
@property (nonatomic) CGFloat originalAvatarImageWidth;
@property (nonatomic) CGFloat originalAvatarImageMarginRight;

// For name hiding.
@property (nonatomic) CGFloat originalNameLabelWidth;

- (void)setUp;
- (void)setUpSubviews;
- (void)tearDownSubviews;

- (void)update;
- (void)updateAppearance;
- (void)updateNameLabel;

- (void)updateButtonType;

- (void)toggleAvatarImageViewHidden;
- (void)toggleNameLabelHidden;

@end

@implementation NBAccountButton

+ (void)initialize
{
    if (self == [NBAccountButton self]) {
        HiddenKeyPath = @"hidden";
        SelectedAccountKeyPath = NSStringFromSelector(@selector(selectedAccount));
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}
- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setUp];
}
- (void)dealloc
{
    [self tearDownSubviews];
}

- (void)setUp
{
    self.shouldUseCircleAvatarFrame = NO;
    [self setUpSubviews];
    [self update];
    self.buttonType = NBAccountButtonTypeDefault;
}

#pragma mark - UIControl

- (void)setHighlighted:(BOOL)highlighted
{
    super.highlighted = highlighted;
    [UIView animateWithDuration:self.highlightAnimationDuration.floatValue delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction
                     animations:^{ self.alpha = highlighted ? self.dimmedAlpha.floatValue : 1.0f; }
                     completion:nil];
}

#pragma mark - UIView

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize newSize = [super sizeThatFits:size];
    // Guard.
    if (!self.barButtonItem) {
        return newSize;
    }
    // Non-AutoLayout adjustments.
    CGFloat width = 0.0f;
    if (!self.nameLabel.isHidden) {
        width += self.originalNameLabelWidth;
    }
    if (!(self.avatarImageView.isHidden || self.nameLabel.isHidden)) {
        width += self.originalAvatarImageWidth + self.originalAvatarImageMarginRight;
    }
    if (width > 0.0f) {
        newSize.width = width;
    }
    return newSize;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    [self updateAppearance];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != &observationContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if ([keyPath isEqual:HiddenKeyPath]) {
        if (object == self.avatarImageView) {
            [self toggleAvatarImageViewHidden];
        } else if (object == self.nameLabel) {
            [self toggleNameLabelHidden];
        }
    }
    if (object == self.dataSources && [keyPath isEqual:SelectedAccountKeyPath]) {
        self.dataSource = self.dataSources.selectedAccount;
    }
}

#pragma mark - Public

+ (NBAccountButton *)accountButtonFromNibWithTarget:(id)target action:(SEL)action
{
    NBAccountButton *accountButton = [[NSBundle bundleForClass:[NBAccountButton class]] loadNibNamed:@"NBAccountButton" owner:self options:nil].firstObject;
    [accountButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return accountButton;
}

#pragma mark Accessors

- (void)setDataSource:(id<NBAccountViewDataSource>)dataSource
{
    _dataSource = dataSource;
    // Did.
    if (dataSource) {
        self.avatarImageView.image = [UIImage imageWithData:dataSource.avatarImageData];
    }
    [self updateButtonType];
    [self update];
}

- (void)setDataSources:(id<NBAccountsViewDataSource>)dataSources
{
    // Will.
    if (self.dataSources) {
        [(id)self.dataSources removeObserver:self forKeyPath:SelectedAccountKeyPath context:&observationContext];
    }
    // Set.
    _dataSources = dataSources;
    // Did.
    if (self.dataSources) {
        [(id)self.dataSources addObserver:self forKeyPath:SelectedAccountKeyPath options:0 context:&observationContext];
    }
}

- (void)setButtonType:(NBAccountButtonType)buttonType
{
    // Set.
    _buttonType = buttonType;
    // Did.
    [self updateButtonType];
}

- (void)setShouldUseCircleAvatarFrame:(BOOL)shouldUseCircleAvatarFrame
{
    // Set.
    _shouldUseCircleAvatarFrame = shouldUseCircleAvatarFrame;
    // Did.
    self.avatarImageView.layer.cornerRadius = (shouldUseCircleAvatarFrame
                                               ? self.avatarImageView.frame.size.width / 2.0f
                                               : self.cornerRadius.floatValue);
}

- (UIBarButtonItem *)barButtonItemWithCompactButtonType:(NBAccountButtonType)compactButtonType
{
    if (self.barButtonItem) {
        return self.barButtonItem;
    }
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.buttonType = compactButtonType;
    }
    self.barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self];
    return self.barButtonItem;
}

#pragma mark - Private

- (void)setUpSubviews
{
    self.avatarImageView.layer.borderWidth = 1.0f;
    // Set up avatar hiding.
    [self.avatarImageView addObserver:self forKeyPath:HiddenKeyPath options:0 context:&observationContext];
    self.originalAvatarImageWidth = self.avatarImageWidth.constant;
    self.originalAvatarImageMarginRight = self.avatarImageMarginRight.constant;
    // Set up name hiding.
    [self.nameLabel addObserver:self forKeyPath:HiddenKeyPath options:0 context:&observationContext];
}
- (void)tearDownSubviews
{
    [self.avatarImageView removeObserver:self forKeyPath:HiddenKeyPath context:&observationContext];
    [self.nameLabel removeObserver:self forKeyPath:HiddenKeyPath context:&observationContext];
}

- (void)update
{
    [self updateAppearance];
    [self updateNameLabel];
    [self sizeToFit];
}

- (void)updateAppearance
{
    // Tint colors.
    self.avatarImageView.layer.borderColor = self.tintColor.CGColor;
    self.nameLabel.textColor = self.tintColor;
}

- (void)updateNameLabel
{
    static UIFont *iconFont; // Not dynamic, so we can cache this.
    static NSString *addUserIcon = @"\ue6a9";
    static NSString *userIcon = @"\ue605";
    static NSString *usersIcon = @"\ue693";
    iconFont = iconFont ?: [UIFont fontWithName:NBIconFontFamilyName size:32.0f];
    if (self.actualButtonType == NBAccountButtonTypeIconOnly) {
        self.nameLabel.font = iconFont;
    }
    if (self.dataSource) {
        if (self.actualButtonType == NBAccountButtonTypeIconOnly) {
            self.nameLabel.text = self.dataSources.accounts.count > 1 ? usersIcon : userIcon;
        } else {
            self.nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            self.nameLabel.text = self.dataSource.name;
        }
    } else {
        if (self.actualButtonType == NBAccountButtonTypeIconOnly) {
            self.nameLabel.text = addUserIcon;
        } else {
            self.nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            self.nameLabel.text = @"label.sign-in".nb_localizedString;
        }
    }
    [self.nameLabel sizeToFit];
    self.originalNameLabelWidth = self.nameLabel.frame.size.width;
}

- (void)updateButtonType
{
    NBAccountButtonType actualButtonType = self.buttonType;
    if (!self.dataSource) {
        if (self.buttonType == NBAccountButtonTypeAvatarOnly) {
            actualButtonType = NBAccountButtonTypeIconOnly;
        } else if (self.buttonType == NBAccountButtonTypeDefault) {
            actualButtonType = NBAccountButtonTypeNameOnly;
        }
    }
    self.actualButtonType = actualButtonType;
}

- (void)toggleAvatarImageViewHidden
{
    self.avatarImageWidth.constant = self.avatarImageView.isHidden ? 0.0f : self.originalAvatarImageWidth;
    self.avatarImageMarginRight.constant = (self.avatarImageView.isHidden || self.nameLabel.isHidden
                                            ? 0.0f : self.originalAvatarImageMarginRight);
    [self setNeedsUpdateConstraints];
}

- (void)toggleNameLabelHidden
{
    CGRect frame = self.nameLabel.frame;
    if (self.nameLabel.isHidden) {
        frame.size.width = 0.0f;
    } else {
        frame.size.width = self.originalNameLabelWidth;
    }
    self.nameLabel.frame = frame;
}

#pragma mark Accessors

- (void)setActualButtonType:(NBAccountButtonType)actualButtonType
{
    _actualButtonType = actualButtonType;
    // Did.
    BOOL shouldHideNameLabel = NO;
    BOOL shouldHideAvatarImageView = NO;
    switch (actualButtonType) {
        case NBAccountButtonTypeIconOnly:
            shouldHideAvatarImageView = YES;
            break;
        case NBAccountButtonTypeAvatarOnly:
            shouldHideNameLabel = YES;
            break;
        case NBAccountButtonTypeNameOnly:
            shouldHideAvatarImageView = YES;
            break;
        case NBAccountButtonTypeDefault: break;
    }
    // Set and trigger related change events.
    self.nameLabel.hidden = shouldHideNameLabel;
    self.avatarImageView.hidden = shouldHideAvatarImageView;
    // Keep the rest of the view updated.
    [self update];
}

@end
