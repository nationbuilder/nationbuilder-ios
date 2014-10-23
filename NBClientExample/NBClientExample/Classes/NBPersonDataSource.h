//
//  NBPersonDataSource.h
//  NBClientExample
//
//  Created by Peng Wang on 7/24/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NBUIDefines.h"

@interface NBPersonDataSource : NSObject <NBDataSource>

@property (nonatomic, strong) NSDictionary *person;

@property (nonatomic, strong) UIImage *profileImage;

- (BOOL)save;
- (void)cancelSave;

@end
