//
//  NBPeopleViewDataSource.h
//  NBClientExample
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NBUIDefines.h"

@interface NBPeopleViewDataSource : NSObject <NBCollectionViewDataSource>

@property (nonatomic, copy, readonly) NSArray *people;
@property (nonatomic, copy, readonly) NSDictionary *personDataSources;

- (void)fetchAll;

@end
