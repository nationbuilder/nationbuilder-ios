//
//  UIKitAdditions.m
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "UIKitAdditions.h"

#import <CoreText/CoreText.h>

#import "FoundationAdditions.h"
#import "NBAccountButton.h"
#import "NBDefines.h"

@implementation UIAlertController (NBAdditions)

+ (UIAlertController *)nb_genericAlertWithError:(NSError *)error
                               defaultDismissal:(BOOL)defaultDismissal
{
    error = error ?: [NSError nb_genericError];
    NSDictionary *userInfo = error.userInfo;
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:userInfo[NSLocalizedDescriptionKey]
                                        message:[userInfo[NSLocalizedFailureReasonErrorKey]
                                                 stringByAppendingFormat:@" %@", (userInfo[NSLocalizedRecoverySuggestionErrorKey] ?: @"")]
                                 preferredStyle:UIAlertControllerStyleAlert];
    if (defaultDismissal) {
        [alert addAction:
         [UIAlertAction actionWithTitle:@"label.ok".nb_localizedString style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
        }]];
    }
    return alert;
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
