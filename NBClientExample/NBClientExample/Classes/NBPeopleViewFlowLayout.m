//
//  NBPeopleViewFlowLayout.m
//  NBClientExample
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import "NBPeopleViewFlowLayout.h"

#if DEBUG
static NBLogLevel LogLevel = NBLogLevelDebug;
#else
static NBLogLevel LogLevel = NBLogLevelWarning;
#endif

@interface NBPeopleViewFlowLayout ()

@property (nonatomic, getter = isLandscape) BOOL landscape;
@property (nonatomic) CGFloat originalItemHeight;

@property (nonatomic, copy) NSArray *decorationViewAttributes;

@end

@implementation NBPeopleViewFlowLayout

- (void)prepareLayout
{
    [super prepareLayout];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.originalItemHeight = self.itemSize.height;
    });
    
    CGFloat fullWidth = self.collectionView.bounds.size.width;
    
    CGSize itemSize = self.itemSize;
    itemSize.width = self.hasMultipleColumns ? (fullWidth / self.numberOfColumnsInMultipleColumnLayout) : fullWidth;
    CGFloat heightScalar = self.isLandscape ? 0.9f : 1.0f;
    itemSize.height = self.originalItemHeight * heightScalar;
    self.itemSize = itemSize;
    
    CGSize headerReferenceSize = self.headerReferenceSize;
    headerReferenceSize.width = fullWidth;
    self.headerReferenceSize = headerReferenceSize;
    
    NSMutableArray *decorationViewAttributes = [NSMutableArray array];
    for (Class aClass in self.decorationViewClasses) {
        NSString *kind = NSStringFromClass(aClass);
        UICollectionViewLayoutAttributes *attributes =
        [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:kind
                                                                    withIndexPath:[NSIndexPath indexPathWithIndex:0]];
        attributes.size = CGSizeMake(80.0f, 60.0f); // TODO: Too magical.
        [decorationViewAttributes addObject:attributes];
    }
    self.decorationViewAttributes = decorationViewAttributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    NBLogDebug(@"Changed bounds: %@", NSStringFromCGRect(newBounds));
    CGRect oldBounds = self.collectionView.bounds;
    if (newBounds.size.width != oldBounds.size.width) {
        self.landscape = newBounds.size.width > oldBounds.size.width;
        return YES;
    } else if (self.collectionView.isDragging &&
               (self.topOffsetOverflow >= 0.0f || self.bottomOffsetOverflow >= 0.0f)
    ) {
        return YES;
    }
    return [super shouldInvalidateLayoutForBoundsChange:newBounds];
}

- (CGSize)collectionViewContentSize
{
    // Ensure minimum content size for scrolling / bouncing.
    CGSize contentSize = self.intrinsicContentSize;
    contentSize.height = MAX(contentSize.height, self.visibleCollectionViewHeight);
    return contentSize;
}

#pragma mark - Decoration Views

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *allAttributes = [super layoutAttributesForElementsInRect:rect].mutableCopy;
    for (Class aClass in self.decorationViewClasses) {
        if ((!self.shouldShowLoadMore && aClass == [NBPeopleLoadMoreDecorationLabel class]) ||
            (!self.shouldShowRefresh && aClass == [NBPeopleRefreshDecorationLabel class])) {
            continue;
        }
        UICollectionViewLayoutAttributes *attributes =
        [self layoutAttributesForDecorationViewOfKind:NSStringFromClass(aClass)
                                          atIndexPath:[NSIndexPath indexPathWithIndex:0]];
        if (attributes) {
            [allAttributes addObject:attributes];
        }
    }
    return allAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)decorationViewKind atIndexPath:(NSIndexPath *)indexPath
{
    static CGFloat alphaDamping = 0.7f;
    UIScrollView *scrollView = self.collectionView;
    CGPoint center = self.collectionView.center;
    CGFloat offsetOverflow = 0.0f;
    CGFloat requiredOffsetOverflow = self.requiredContentOffsetOverflow.floatValue;
    CGFloat baseCenterY = requiredOffsetOverflow / 2.0f;
    // Guard.
    if (scrollView.contentSize.height < requiredOffsetOverflow) {
        return nil;
    }
    // Find stored class and initial attributes.
    UICollectionViewLayoutAttributes *attributes =
    [self.decorationViewAttributes filteredArrayUsingPredicate:
     [NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes *attributes, NSDictionary *bindings) {
        return [attributes.representedElementKind isEqualToString:decorationViewKind];
    }]].firstObject;
    // Customize position.
    if ([decorationViewKind isEqualToString:NSStringFromClass([NBPeopleLoadMoreDecorationLabel class])]) {
        center.y = MAX(scrollView.contentSize.height, self.visibleCollectionViewHeight) + baseCenterY;
        offsetOverflow = self.bottomOffsetOverflow;
    } else if ([decorationViewKind isEqualToString:NSStringFromClass([NBPeopleRefreshDecorationLabel class])]) {
        center.y = -baseCenterY;
        offsetOverflow = self.topOffsetOverflow;
    }
    // Labels also fade in as they come into view.
    CGFloat alpha = powf(offsetOverflow / requiredOffsetOverflow * alphaDamping, 2.0f);
    if (alpha > 0.0f && alpha <= 1.0f) {
        attributes.alpha = alpha;
    }
    NBLogDebug(@"Decoration attributes: %@", attributes);
    attributes.center = center;
    return attributes;
}

#pragma mark - NBLogging

+ (void)updateLoggingToLevel:(NBLogLevel)logLevel
{
    LogLevel = logLevel;
}

#pragma mark - Public

- (NSUInteger)numberOfColumnsInMultipleColumnLayout
{
    if (_numberOfColumnsInMultipleColumnLayout) {
        return _numberOfColumnsInMultipleColumnLayout;
    }
    self.numberOfColumnsInMultipleColumnLayout = 2;
    return _numberOfColumnsInMultipleColumnLayout;
}

- (CGFloat)bottomOffsetOverflow
{
    UIScrollView *scrollView = self.collectionView;
    return scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.bounds.size.height);
}

- (CGFloat)topOffsetOverflow
{
    UIScrollView *scrollView = self.collectionView;
    return -(scrollView.contentOffset.y + scrollView.contentInset.top);
}

- (NSArray *)decorationViewClasses
{
    return @[ [NBPeopleLoadMoreDecorationLabel class], [NBPeopleRefreshDecorationLabel class] ];
}

- (BOOL)hasMultipleColumns
{
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

- (CGSize)intrinsicContentSize
{
    return [super collectionViewContentSize];
}

- (UICollectionViewCell *)previousVerticalCellForCell:(UICollectionViewCell *)cell
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    NSInteger offset = self.hasMultipleColumns ? self.numberOfColumnsInMultipleColumnLayout : 1;
    if (indexPath.item - offset < 0) {
        return nil;
    }
    return [self.collectionView cellForItemAtIndexPath:
            [NSIndexPath indexPathForItem:indexPath.item - offset inSection:indexPath.section]];
}

- (CGFloat)visibleCollectionViewHeight
{
    return self.collectionView.bounds.size.height - self.collectionView.contentInset.top + 1.0f;
}

@end

#pragma mark - Decoration View Classes

// NOTE: These extra classes are due to not being able to configure decoration views directly.

@interface NBPeopleDecorationLabel ()

@property (nonatomic) UILabel *titleLabel;

@end

@implementation NBPeopleDecorationLabel

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.titleLabel];
        self.backgroundColor = [UIColor clearColor];
        self.font = [UIFont boldSystemFontOfSize:13.0f];
        self.textColor = [UIColor blackColor];
    }
    return self;
}

#pragma mark - Public

- (UIFont *)font
{
    return self.titleLabel.font;
}
- (void)setFont:(UIFont *)font
{
    NSString *key = NSStringFromSelector(@selector(font));
    [self willChangeValueForKey:key];
    self.titleLabel.font = font;
    [self didChangeValueForKey:key];
}

- (UIColor *)textColor
{
    return self.titleLabel.textColor;
}
- (void)setTextColor:(UIColor *)textColor
{
    NSString *key = NSStringFromSelector(@selector(textColor));
    [self willChangeValueForKey:key];
    self.titleLabel.textColor = textColor;
    [self didChangeValueForKey:key];
}

@end

@implementation NBPeopleLoadMoreDecorationLabel

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.text = [NSLocalizedString(@"label.load-more", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    }
    return self;
}

@end

@implementation NBPeopleRefreshDecorationLabel

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.text = [NSLocalizedString(@"label.refresh", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    }
    return self;
}

@end