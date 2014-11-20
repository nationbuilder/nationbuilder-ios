//
//  NBPersonViewController.h
//  NBClientExample
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NBUIDefines.h"

typedef NS_ENUM(NSUInteger, NBPersonViewControllerMode) {
    NBPersonViewControllerModeViewAndEdit,
    NBPersonViewControllerModeCreate,
};

@interface NBPersonViewController : UIViewController <NBViewController>

@property (nonatomic) NSNumber *editingAnimationDuration UI_APPEARANCE_SELECTOR;
@property (nonatomic) UIColor *editingBackgroundColor UI_APPEARANCE_SELECTOR;
@property (nonatomic) NSNumber *subviewCornerRadius UI_APPEARANCE_SELECTOR;
@property (nonatomic, copy) NSString *tagDelimiterString UI_APPEARANCE_SELECTOR;
@property (nonatomic) CGSize textFieldInsetSize UI_APPEARANCE_SELECTOR;

@property (nonatomic) NBPersonViewControllerMode mode;

@end

@interface NBTextField : UITextField @end
