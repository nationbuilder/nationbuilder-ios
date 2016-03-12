//
//  NBClient+Lists.m
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBClient+Lists.h"
#import "NBClient_Internal.h"

#import "FoundationAdditions.h"
#import "NBPaginationInfo.h"

@implementation NBClient (Lists)

- (NSURLSessionDataTask *)fetchListsWithPaginationInfo:(NBPaginationInfo *)paginationInfo
                                     completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    return [self fetchByResourceSubPath:@"/lists" withParameters:nil customResultsKey:nil paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchListPeopleByIdentifier:(NSUInteger)identifier
                                   withPaginationInfo:(NBPaginationInfo *)paginationInfo
                                    completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    return [self fetchByResourceSubPath:[NSString stringWithFormat:@"/lists/%lu/people", (unsigned long)identifier]
                         withParameters:nil customResultsKey:nil paginationInfo:paginationInfo completionHandler:completionHandler];
}

// TODO: Deprecate to use NBClientEmptyCompletionHandler.
- (NSURLSessionDataTask *)createPeopleListingsByIdentifier:(NSUInteger)listIdentifier
                                     withPeopleIdentifiers:(NSArray *)peopleIdentifiers
                                         completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    return [self createByResourceSubPath:[NSString stringWithFormat:@"/lists/%lu/people", (unsigned long)listIdentifier]
                          withParameters:@{ @"people_ids": peopleIdentifiers } resultsKey:nil completionHandler:completionHandler];
}

// TODO: Deprecate to use NBClientEmptyCompletionHandler.
- (NSURLSessionDataTask *)deletePeopleListingsByIdentifier:(NSUInteger)listIdentifier
                                     withPeopleIdentifiers:(NSArray *)peopleIdentifiers
                                         completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    return [self deleteByResourceSubPath:[NSString stringWithFormat:@"/lists/%lu/people", (unsigned long)listIdentifier]
                          withParameters:@{ @"people_ids": peopleIdentifiers } resultsKey:nil completionHandler:completionHandler];
}

@end
