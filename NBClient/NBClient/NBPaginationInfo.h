//
//  NBPaginationInfo.h
//  NBClient
//
//  Created by Peng Wang on 7/21/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NBDefines.h"

extern NSString * const NBClientCurrentPageNumberKey;
extern NSString * const NBClientNumberOfTotalPagesKey;
extern NSString * const NBClientNumberOfItemsPerPageKey;
extern NSString * const NBClientNumberOfTotalItemsKey;

@interface NBPaginationInfo : NSObject <NBDictionarySerializing>

@property (nonatomic) NSUInteger currentPageNumber;
@property (nonatomic) NSUInteger numberOfTotalPages;
@property (nonatomic) NSUInteger numberOfItemsPerPage;
@property (nonatomic) NSUInteger numberOfTotalItems;

@end
