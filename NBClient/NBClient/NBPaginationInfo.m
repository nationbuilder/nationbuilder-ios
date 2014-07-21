//
//  NBPaginationInfo.m
//  NBClient
//
//  Created by Peng Wang on 7/21/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBPaginationInfo.h"

NSString * const NBClientCurrentPageNumberKey = @"page";
NSString * const NBClientNumberOfTotalPagesKey = @"total_pages";
NSString * const NBClientNumberOfItemsPerPageKey = @"per_page";
NSString * const NBClientNumberOfTotalItemsKey = @"total";

@implementation NBPaginationInfo

#pragma mark - NBDictionarySerializing

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [self init];
    if (self) {
        self.currentPageNumber = [dictionary[NBClientCurrentPageNumberKey] unsignedIntegerValue];
        self.numberOfTotalPages = [dictionary[NBClientNumberOfTotalPagesKey] unsignedIntegerValue];
        self.numberOfItemsPerPage = [dictionary[NBClientNumberOfItemsPerPageKey] unsignedIntegerValue];
        self.numberOfTotalItems = [dictionary[NBClientNumberOfTotalItemsKey] unsignedIntegerValue];
    }
    return self;
}

- (NSDictionary *)dictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[NBClientCurrentPageNumberKey] = @(self.currentPageNumber);
    dictionary[NBClientNumberOfTotalPagesKey] = @(self.numberOfTotalPages);
    dictionary[NBClientNumberOfItemsPerPageKey] = @(self.numberOfItemsPerPage);
    dictionary[NBClientNumberOfTotalItemsKey] = @(self.numberOfTotalItems);
    return dictionary;
}

- (BOOL)isEqualToDictionary:(NSDictionary *)dictionary
{
    return ([dictionary[NBClientCurrentPageNumberKey] isEqual:@(self.currentPageNumber)] &&
            [dictionary[NBClientNumberOfTotalPagesKey] isEqual:@(self.numberOfTotalPages)] &&
            [dictionary[NBClientNumberOfItemsPerPageKey] isEqual:@(self.numberOfItemsPerPage)] &&
            [dictionary[NBClientNumberOfTotalItemsKey] isEqual:@(self.numberOfTotalItems)]);
}

@end
