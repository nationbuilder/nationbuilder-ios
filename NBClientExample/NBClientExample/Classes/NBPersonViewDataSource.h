//
//  NBPersonViewDataSource.h
//  NBClientExample
//
//  Copyright (MIT) 2014-present NationBuilder
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
