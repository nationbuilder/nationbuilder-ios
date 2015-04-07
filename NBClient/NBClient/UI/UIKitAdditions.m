//
//  UIKitAdditions.m
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import "UIKitAdditions.h"

#import <CoreText/CoreText.h>

#import "FoundationAdditions.h"
#import "NBAccountButton.h"
#import "NBDefines.h"

@implementation UIAlertView (NBAdditions)

+ (UIAlertView *)nb_genericAlertViewWithError:(NSError *)error
{
    error = error ?: [NSError nb_genericError];
    NSDictionary *userInfo = error.userInfo;
    return [[UIAlertView alloc] initWithTitle:userInfo[NSLocalizedDescriptionKey]
                                      message:[userInfo[NSLocalizedFailureReasonErrorKey]
                                               stringByAppendingFormat:@" %@", (userInfo[NSLocalizedRecoverySuggestionErrorKey] ?: @"")]
                                     delegate:self cancelButtonTitle:nil
                            otherButtonTitles:@"label.ok".nb_localizedString, nil];
}

@end

@implementation UIApplication (NBAdditions)

- (void)nb_loadBundleResources
{
    NSString *iconFontPath = [[NSBundle bundleForClass:[NBAccountButton class]] pathForResource:NBIconFontFamilyName ofType:@"ttf"];
    NSData *iconFontData = [NSData dataWithContentsOfFile:iconFontPath];
    CFErrorRef error;
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)iconFontData);
    CGFontRef iconFont = CGFontCreateWithDataProvider(provider);
    if (!CTFontManagerRegisterGraphicsFont(iconFont, &error)) {
        CFStringRef errorDescription = CFErrorCopyDescription(error);
        NBLog(@"ERROR: Failed to load font: %@", errorDescription);
        CFRelease(errorDescription);
    }
    CFRelease(iconFont);
    CFRelease(provider);
}

@end

@implementation UIView (NBAdditions)

- (NSLayoutConstraint *)nb_addCenterXConstraintToSuperview
{
    if (self.translatesAutoresizingMaskIntoConstraints) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    NSLayoutConstraint *constraint =
    [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterX
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self.superview attribute:NSLayoutAttributeCenterX
                                multiplier:1.0f constant:0.0f];
    [self.superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)nb_addCenterYConstraintToSuperview
{
    if (self.translatesAutoresizingMaskIntoConstraints) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    NSLayoutConstraint *constraint =
    [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterY
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self.superview attribute:NSLayoutAttributeCenterY
                                multiplier:1.0f constant:0.0f];
    [self.superview addConstraint:constraint];
    return constraint;
}

@end
