//
//  NBClient+Lists.h
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBClient.h"

@interface NBClient (Lists)

/**
 Lists (Partial)
 
 The endpoint annotations are for reference only to link to the API docs and may
 change independently of the method selectors below.
 
 The order of the methods listing attempts to mirror that of apiexplorer.nationbuilder.com.
 */

// GET /lists
- (nonnull NSURLSessionDataTask *)fetchListsWithPaginationInfo:(nullable NBPaginationInfo *)paginationInfo
                                             completionHandler:(nonnull NBClientResourceListCompletionHandler)completionHandler;

// GET /lists/:id/people
- (nonnull NSURLSessionDataTask *)fetchListPeopleByIdentifier:(NSUInteger)identifier
                                           withPaginationInfo:(nullable NBPaginationInfo *)paginationInfo
                                            completionHandler:(nonnull NBClientResourceListCompletionHandler)completionHandler;

// POST /lists/:id/people
- (nonnull NSURLSessionDataTask *)createPeopleListingsByIdentifier:(NSUInteger)identifier
                                             withPeopleIdentifiers:(nonnull NSArray *)peopleIdentifiers
                                                 completionHandler:(nonnull NBClientResourceItemCompletionHandler)completionHandler;

// DELETE /lists/:id/people
- (nonnull NSURLSessionDataTask *)deletePeopleListingsByIdentifier:(NSUInteger)identifier
                                             withPeopleIdentifiers:(nonnull NSArray *)peopleIdentifiers
                                                 completionHandler:(nonnull NBClientResourceItemCompletionHandler)completionHandler;

@end
