//
//  UIKitAdditions.h
//  NBClient
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertView (NBAdditions)

+ (UIAlertView *)nb_genericAlertViewWithError:(NSError *)error;

@end

@interface UIView (NBAdditions)

- (NSLayoutConstraint *)nb_addCenterXConstraintToSuperview;
- (NSLayoutConstraint *)nb_addCenterYConstraintToSuperview;

@end
