//
//  NBPersonViewDataSource.h
//  NBClientExample
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NBUIDefines.h"

@interface NBPersonViewDataSource : NSObject <NBViewDataSource>

@property (nonatomic, copy) NSDictionary *person;

@property (nonatomic) UIImage *profileImage;

- (BOOL)save;
- (void)cancelSave;

- (BOOL)nb_delete;
- (void)cancelDelete;

@end
