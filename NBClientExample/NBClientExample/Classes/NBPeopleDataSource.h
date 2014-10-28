//
//  NBPeopleDataSource.h
//  NBClientExample
//
//  Created by Peng Wang on 7/23/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NBUIDefines.h"

@interface NBPeopleDataSource : NSObject <NBCollectionDataSource>

@property (nonatomic, strong, readonly) NSArray *people;
@property (nonatomic, strong, readonly) NSDictionary *personDataSources;

- (void)fetchAll;

@end
