//
//  UIKitAdditions.h
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import <UIKit/UIKit.h>

@interface UIAlertView (NBAdditions)

+ (nonnull UIAlertView *)nb_genericAlertViewWithError:(nonnull NSError *)error;

@end

@interface UIApplication (NBAdditions)

- (void)nb_loadBundleResources;

@end

@interface UIView (NBAdditions)

- (nonnull NSLayoutConstraint *)nb_addCenterXConstraintToSuperview;
- (nonnull NSLayoutConstraint *)nb_addCenterYConstraintToSuperview;

@end
