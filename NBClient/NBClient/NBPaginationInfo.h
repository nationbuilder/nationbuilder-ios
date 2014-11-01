//
//  NBPaginationInfo.h
//  NBClient
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NBDefines.h"

extern NSString * const NBClientCurrentPageNumberKey;
extern NSString * const NBClientNumberOfTotalPagesKey;
extern NSString * const NBClientNumberOfItemsPerPageKey;
extern NSString * const NBClientNumberOfTotalItemsKey;

@interface NBPaginationInfo : NSObject <NBDictionarySerializing>

@property (nonatomic) NSUInteger currentPageNumber; // Starts at 1s.
@property (nonatomic) NSUInteger numberOfTotalPages;
@property (nonatomic) NSUInteger numberOfItemsPerPage;
@property (nonatomic) NSUInteger numberOfTotalItems;

@property (nonatomic) NSUInteger numberOfTotalAvailableItems;

- (NSUInteger)indexOfFirstItemAtPage:(NSUInteger)pageNumber;
- (NSUInteger)numberOfItemsAtPage:(NSUInteger)pageNumber;

@end
