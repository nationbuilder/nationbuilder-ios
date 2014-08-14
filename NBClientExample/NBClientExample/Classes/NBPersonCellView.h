//
//  NBPersonCellView.h
//  NBClientExample
//
//  Created by Peng Wang on 7/23/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NBUIDefines.h"

@interface NBPersonCellView : UICollectionViewCell <NBViewCell>

@property (nonatomic, weak, readonly) UIView *bottomBorderView;

@property (nonatomic, strong) UIColor *borderColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) NSNumber *deleteSwitchDimmedAlpha UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) UIColor *highlightedBackgroundColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) UIColor *selectedBackgroundColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *selectedForegroundColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) NSString *tagDelimiterString UI_APPEARANCE_SELECTOR;

@property (nonatomic, getter = areBordersDisabled) BOOL bordersDisabled;

@property (nonatomic, weak) id<NBCollectionViewCellDelegate> delegate;

@end

