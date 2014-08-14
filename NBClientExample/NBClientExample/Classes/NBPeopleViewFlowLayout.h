//
//  NBPeopleViewFlowLayout.h
//  NBClientExample
//
//  Created by Peng Wang on 8/5/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NBUIDefines.h"

@interface NBPeopleViewFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, strong) NSNumber *contentInsetAnimationDuration;

@property (nonatomic, strong) NSNumber *requiredContentOffsetOverflow;

@property (nonatomic) UIEdgeInsets originalContentInset;

@property (nonatomic) NSUInteger numberOfColumnsInMultipleColumnLayout;

@property (nonatomic, readonly) CGFloat bottomOffsetOverflow;
@property (nonatomic, readonly) CGFloat topOffsetOverflow;

@property (nonatomic, readonly) NSArray *decorationViewClasses;

@property (nonatomic, readonly) BOOL hasMultipleColumns;
@property (nonatomic, readonly) CGSize intrinsicContentSize;

@property (nonatomic) BOOL shouldShowLoadMore;

- (UICollectionViewCell *)previousVerticalCellForCell:(UICollectionViewCell *)cell;

@end

@interface NBPeopleDecorationLabel : UICollectionReusableView

@property (strong, nonatomic) UIFont *font UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor *textColor UI_APPEARANCE_SELECTOR;

@end

@interface NBPeopleLoadMoreDecorationLabel : NBPeopleDecorationLabel @end
@interface NBPeopleRefreshDecorationLabel : NBPeopleDecorationLabel @end