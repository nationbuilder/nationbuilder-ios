//
//  NBPeopleViewDataSource.h
//  NBClientExample
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import <Foundation/Foundation.h>

#import "NBUIDefines.h"

@interface NBPeopleViewDataSource : NSObject <NBCollectionViewDataSource>

@property (nonatomic, copy, readonly) NSArray *people;
@property (nonatomic, copy, readonly) NSDictionary *personDataSources;

- (void)fetchAll;

@end
