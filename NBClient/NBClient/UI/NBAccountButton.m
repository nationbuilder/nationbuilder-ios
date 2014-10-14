//
//  NBAccountButton.m
//  NBClient
//
//  Created by Peng Wang on 10/7/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBAccountButton.h"

#import "QuartzCore/QuartzCore.h"

@interface NBAccountButton ()

@property (nonatomic, weak, readwrite) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak, readwrite) IBOutlet UIImageView *avatarImageView;

- (void)setUp;

@end

@implementation NBAccountButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void)awakeFromNib
{
    self.avatarImageView.layer.cornerRadius = 2.0f;
}

- (void)setUp
{}

@end
