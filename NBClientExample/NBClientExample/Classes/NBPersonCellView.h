//
//  NBPersonCellView.h
//  NBClientExample
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NBUIDefines.h"

@interface NBPersonCellView : UICollectionViewCell <NBViewCell>

@property (nonatomic, weak, readonly) UIView *bottomBorderView;

@property (nonatomic) UIColor *borderColor UI_APPEARANCE_SELECTOR;

@property (nonatomic) UIColor *highlightedBackgroundColor UI_APPEARANCE_SELECTOR;

@property (nonatomic) UIColor *selectedBackgroundColor UI_APPEARANCE_SELECTOR;
@property (nonatomic) UIColor *selectedForegroundColor UI_APPEARANCE_SELECTOR;

@property (nonatomic) NSString *tagDelimiterString UI_APPEARANCE_SELECTOR;

@property (nonatomic, getter = areBordersDisabled) BOOL bordersDisabled;

@property (nonatomic, weak) id<NBCollectionViewCellDelegate> delegate;

@end

