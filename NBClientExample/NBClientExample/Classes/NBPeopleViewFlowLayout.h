//
//  NBPeopleViewFlowLayout.h
//  NBClientExample
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import <UIKit/UIKit.h>

#import "NBUIDefines.h"

@interface NBPeopleViewFlowLayout : UICollectionViewFlowLayout <NBLogging>

@property (nonatomic) NSNumber *contentInsetAnimationDuration;

@property (nonatomic) NSNumber *requiredContentOffsetOverflow;

@property (nonatomic) UIEdgeInsets originalContentInset;

@property (nonatomic) NSUInteger numberOfColumnsInMultipleColumnLayout;

@property (nonatomic, readonly) CGFloat bottomOffsetOverflow;
@property (nonatomic, readonly) CGFloat topOffsetOverflow;

@property (nonatomic, copy, readonly) NSArray *decorationViewClasses;

@property (nonatomic, readonly) BOOL hasMultipleColumns;
@property (nonatomic, readonly) CGSize intrinsicContentSize;
@property (nonatomic, readonly) CGFloat visibleCollectionViewHeight;

@property (nonatomic) BOOL shouldShowRefresh;
@property (nonatomic) BOOL shouldShowLoadMore;

- (UICollectionViewCell *)previousVerticalCellForCell:(UICollectionViewCell *)cell;

@end

@interface NBPeopleDecorationLabel : UICollectionReusableView

@property (nonatomic) UIFont *font UI_APPEARANCE_SELECTOR;
@property (nonatomic) UIColor *textColor UI_APPEARANCE_SELECTOR;

@end

@interface NBPeopleLoadMoreDecorationLabel : NBPeopleDecorationLabel @end
@interface NBPeopleRefreshDecorationLabel : NBPeopleDecorationLabel @end