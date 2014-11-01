//
//  NBPeopleDataSource.h
//  NBClientExample
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NBUIDefines.h"

@interface NBPeopleDataSource : NSObject <NBCollectionDataSource>

@property (nonatomic, strong, readonly) NSArray *people;
@property (nonatomic, strong, readonly) NSDictionary *personDataSources;

- (void)fetchAll;

@end
