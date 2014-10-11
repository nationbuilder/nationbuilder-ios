//
//  UIKitAdditions.m
//  NBClient
//
//  Created by Peng Wang on 7/11/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "UIKitAdditions.h"

@implementation UIAlertView (NBAdditions)

+ (UIAlertView *)nb_genericAlertViewWithError:(NSError *)error
{
    NSDictionary *userInfo = error.userInfo;
    return [[UIAlertView alloc] initWithTitle:userInfo[NSLocalizedDescriptionKey]
                                      message:[userInfo[NSLocalizedFailureReasonErrorKey]
                                               stringByAppendingString:userInfo[NSLocalizedRecoverySuggestionErrorKey]]
                                     delegate:self cancelButtonTitle:nil
                            otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
}

@end