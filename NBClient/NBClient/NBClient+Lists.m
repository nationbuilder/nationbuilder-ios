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
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:@"/lists"];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"results" paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchListPeopleByIdentifier:(NSUInteger)identifier
                                   withPaginationInfo:(NBPaginationInfo *)paginationInfo
                                    completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/lists/%lu/people", (unsigned long)identifier]];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"results" paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)createPeopleListingsByIdentifier:(NSUInteger)identifier
                                     withPeopleIdentifiers:(NSArray *)peopleIdentifiers
                                         completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/lists/%lu/people", (unsigned long)identifier]];
    return [self baseCreateTaskWithURL:components.URL parameters:@{ @"people_ids": peopleIdentifiers } resultsKey:nil completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)deletePeopleListingsByIdentifier:(NSUInteger)identifier
                                     withPeopleIdentifiers:(NSArray *)peopleIdentifiers
                                         completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/lists/%lu/people", (unsigned long)identifier]];
    return [self baseDeleteTaskWithURL:components.URL parameters:@{ @"people_ids": peopleIdentifiers } resultsKey:nil completionHandler:completionHandler];
}

@end
