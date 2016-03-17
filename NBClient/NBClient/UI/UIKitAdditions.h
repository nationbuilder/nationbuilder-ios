//
//  UIKitAdditions.h
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import <UIKit/UIKit.h>

@interface UIAlertController (NBAdditions)

+ (nonnull UIAlertController *)nb_genericAlertWithError:(nonnull NSError *)error
                                       defaultDismissal:(BOOL)defaultDismissal;

@end

@interface UIApplication (NBAdditions)

- (void)nb_loadBundleResources;

@end

@interface UIView (NBAdditions)

- (nonnull NSLayoutConstraint *)nb_addCenterXConstraintToSuperview;
- (nonnull NSLayoutConstraint *)nb_addCenterYConstraintToSuperview;

@end
