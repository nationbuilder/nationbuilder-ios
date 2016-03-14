//
//  NBPersonCellView.h
//  NBClientExample
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import <UIKit/UIKit.h>

#import "NBUIDefines.h"

@interface NBPersonCellView : UICollectionViewCell <NBViewCell>

@property (nonatomic, weak, readonly) UIView *bottomBorderView;

@property (nonatomic) UIColor *borderColor UI_APPEARANCE_SELECTOR;

@property (nonatomic) UIColor *highlightedBackgroundColor UI_APPEARANCE_SELECTOR;

@property (nonatomic) UIColor *selectedBackgroundColor UI_APPEARANCE_SELECTOR;
@property (nonatomic) UIColor *selectedForegroundColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, copy) NSString *tagDelimiterString UI_APPEARANCE_SELECTOR;

@property (nonatomic, getter = areBordersDisabled) BOOL bordersDisabled;

@property (nonatomic, weak) id<NBCollectionViewCellDelegate> delegate;

@end

