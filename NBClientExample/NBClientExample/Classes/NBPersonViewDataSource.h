//
//  NBPersonViewDataSource.h
//  NBClientExample
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NBUIDefines.h"

@interface NBPersonViewDataSource : NSObject <NBViewDataSource>

@property (nonatomic, strong) NSDictionary *person;

@property (nonatomic, strong) UIImage *profileImage;

- (BOOL)save;
- (void)cancelSave;

- (BOOL)nb_delete;
- (void)cancelDelete;

@end
