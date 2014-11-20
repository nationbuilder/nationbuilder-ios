//
//  NBPersonCellView.m
//  NBClientExample
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBPersonCellView.h"

#import "NBPersonViewDataSource.h"

static NSString *LabelViewKey = @"view";
static NSString *LabelOriginalColorKey = @"originalColor";

#if DEBUG
static NBLogLevel LogLevel = NBLogLevelDebug;
#else
static NBLogLevel LogLevel = NBLogLevelWarning;
#endif

@interface NBPersonCellView ()

@property (nonatomic, weak, readwrite) IBOutlet UIView *bottomBorderView;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *tagsLabel;
@property (nonatomic, copy) NSArray *borderViews;
@property (nonatomic, copy) NSArray *labeledViews;

@end

@implementation NBPersonCellView

@synthesize dataSource = _dataSource;

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.bottomBorderView.backgroundColor = self.borderColor;
    if (!self.selectedBackgroundColor) {
        self.selectedBackgroundColor = self.tintColor;
    }
    self.selectedBackgroundView = [[UIView alloc] init];
}

- (void)dealloc
{
    self.dataSource = nil;
}

- (void)prepareForReuse
{
    self.dataSource = nil;
    self.highlighted = NO;
    self.selected = NO;
}

- (void)setHighlighted:(BOOL)highlighted
{
    super.highlighted = highlighted;
    self.selectedBackgroundView.backgroundColor = self.highlightedBackgroundColor;
    if (!self.areBordersDisabled) {
        for (UIView *view in self.borderViews) {
            view.hidden = highlighted;
        }
    }
    [self.delegate collectionViewCell:self didSetHighlighted:highlighted];
}

- (void)setSelected:(BOOL)selected
{
    super.selected = selected;
    self.selectedBackgroundView.backgroundColor = self.selectedBackgroundColor;
    if (!self.areBordersDisabled) {
        for (UIView *view in self.borderViews) {
            view.hidden = selected;
        }
    }
    for (NSDictionary *view in self.labeledViews) {
        UIColor *color = selected ? self.selectedForegroundColor : view[LabelOriginalColorKey];
        [view[LabelViewKey] setTextColor:color];
    }
    [self.delegate collectionViewCell:self didSetSelected:selected];
}

#pragma mark - NBViewCell

+ (void)updateLoggingToLevel:(NBLogLevel)logLevel
{
    LogLevel = logLevel;
}

- (void)refreshWithData:(NSDictionary *)data
{
    if (data) {
        self.nameLabel.text = data[@"full_name"];
        self.tagsLabel.text = [data[@"tags"] componentsJoinedByString:
                               [NSString stringWithFormat:@" %@ ", self.tagDelimiterString]];
    } else {
        self.nameLabel.text =
        self.tagsLabel.text = nil;
    }
}

- (void)setDataSource:(id<NBViewDataSource>)dataSource
{
    _dataSource = dataSource;
    // Set up.
    if (self.dataSource) {
        NSAssert([self.dataSource isKindOfClass:[NBPersonViewDataSource class]], @"Data source must be of certain type.");
        NBPersonViewDataSource *dataSource = self.dataSource;
        [self refreshWithData:dataSource.person];
    } else {
        [self refreshWithData:nil];
    }
}

#pragma mark - Public

- (void)setBorderColor:(UIColor *)borderColor
{
    _borderColor = borderColor;
    // Did.
    self.bottomBorderView.backgroundColor = borderColor;
}

- (void)setSelectedBackgroundColor:(UIColor *)selectedBackgroundColor
{
    _selectedBackgroundColor = selectedBackgroundColor;
    // Did.
    self.selectedBackgroundView.backgroundColor = selectedBackgroundColor;
}

- (void)setBordersDisabled:(BOOL)bordersDisabled
{
    _bordersDisabled = bordersDisabled;
    // Did.
    for (UIView *view in self.borderViews) {
        view.hidden = self.areBordersDisabled;
    }
}

#pragma mark - Private

- (NSArray *)borderViews
{
    if (_borderViews) {
        return _borderViews;
    }
    self.borderViews = @[ self.bottomBorderView ];
    return _borderViews;
}

- (NSArray *)labeledViews
{
    if (_labeledViews) {
        return _labeledViews;
    }
    NSMutableArray *views = [NSMutableArray array];
    for (id view in @[ self.nameLabel, self.tagsLabel ]) {
        [views addObject:@{ LabelViewKey: view,
                            LabelOriginalColorKey: [view textColor] }];
    }
    self.labeledViews = views;
    return _labeledViews;
}

@end
