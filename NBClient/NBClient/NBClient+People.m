//
//  NBClient+People.m
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import "NBClient+People.h"

#import "FoundationAdditions.h"
#import "NBPaginationInfo.h"
#import "NBClient_Internal.h" // Only needed for a couple endpoints.

@implementation NBClient (People)

#pragma mark - Fetch

- (NSURLSessionDataTask *)fetchPeopleWithPaginationInfo:(NBPaginationInfo *)paginationInfo
                                      completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    return [self fetchByResourceSubPath:@"/people" withParameters:nil customResultsKey:nil paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchPeopleCountWithCompletionHandler:(NBClientResourceCompletionHandler)completionHandler
{
    return [self fetchByResourceSubPath:@"/people/count" withParameters:nil customResultsKey:@"people_count" paginationInfo:nil completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchPersonByIdentifier:(NSUInteger)identifier
                            withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    return [self fetchByResourceSubPath:[NSString stringWithFormat:@"/people/%lu", (unsigned long)identifier]
                         withParameters:nil customResultsKey:@"person" paginationInfo:nil completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchPeopleByParameters:(NSDictionary *)parameters
                               withPaginationInfo:(NBPaginationInfo *)paginationInfo
                                completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    return [self fetchByResourceSubPath:@"/people/search" withParameters:parameters customResultsKey:nil paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchPeopleNearbyByLocationInfo:(NSDictionary *)locationInfo
                                       withPaginationInfo:(NBPaginationInfo *)paginationInfo
                                        completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    NSDictionary *parameters = @{
      @"location": [NSString stringWithFormat:@"%@,%@", locationInfo[NBClientLocationLatitudeKey], locationInfo[NBClientLocationLongitudeKey]],
      @"distance": !locationInfo[NBClientLocationProximityDistanceKey] ? @1 : locationInfo[NBClientLocationProximityDistanceKey]
    };
    return [self fetchByResourceSubPath:@"/people/nearby" withParameters:parameters customResultsKey:nil paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchPersonForClientUserWithCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    return [self fetchByResourceSubPath:@"/people/me" withParameters:nil customResultsKey:@"person" paginationInfo:nil completionHandler:completionHandler];
}

// TODO: Deprecate to use NBClientEmptyCompletionHandler.
- (NSURLSessionDataTask *)registerPersonByIdentifier:(NSUInteger)identifier
                               withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    return [self baseDataTaskWithURLComponents:[self urlComponentsForSubPath:[NSString stringWithFormat:@"/people/%lu/register", (unsigned long)identifier]]
                                    httpMethod:@"GET" parameters:nil resultsKey:nil paginationInfo:nil completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchPersonByParameters:(NSDictionary *)parameters
                            withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    return [self fetchByResourceSubPath:@"/people/match" withParameters:parameters customResultsKey:@"person" paginationInfo:nil completionHandler:completionHandler];
}

#pragma mark - Taggings

- (NSURLSessionDataTask *)fetchPersonTaggingsByIdentifier:(NSUInteger)personIdentifier
                                    withCompletionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    return [self fetchByResourceSubPath:[NSString stringWithFormat:@"/people/%lu/taggings", (unsigned long)personIdentifier]
                         withParameters:nil customResultsKey:@"taggings" paginationInfo:nil completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)createPersonTaggingByIdentifier:(NSUInteger)personIdentifier
                                          withTaggingInfo:(NSDictionary *)taggingInfo
                                        completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    return [self saveByResourceSubPath:[NSString stringWithFormat:@"/people/%lu/taggings", (unsigned long)personIdentifier]
                        withParameters:@{ @"tagging": taggingInfo } resultsKey:@"tagging" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)createPersonTaggingsByIdentifier:(NSUInteger)personIdentifier
                                           withTaggingInfo:(NSDictionary *)taggingInfo
                                         completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    return [self saveByResourceSubPath:[NSString stringWithFormat:@"/people/%lu/taggings", (unsigned long)personIdentifier]
                        withParameters:@{ @"tagging": taggingInfo } resultsKey:@"taggings" completionHandler:completionHandler];
}

// TODO: Deprecate to use NBClientEmptyCompletionHandler.
- (NSURLSessionDataTask *)deletePersonTaggingsByIdentifier:(NSUInteger)personIdentifier
                                                  tagNames:(NSArray *)tagNames
                                     withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSString *subPath = [NSString stringWithFormat:@"/people/%lu/taggings", (unsigned long)personIdentifier];
    if (tagNames.count > 1) { // Bulk.
        return [self deleteByResourceSubPath:subPath withParameters:@{ @"tagging": @{ NBClientTaggingTagNameOrListKey: tagNames } }
                                  resultsKey:nil completionHandler:completionHandler];
    }
    // Use the non-bulk endpoint if we can.
    subPath = [subPath stringByAppendingPathComponent:tagNames.firstObject];
    return [self deleteByResourceSubPath:subPath withParameters:nil resultsKey:nil completionHandler:completionHandler];
}

#pragma mark - Political Capital

- (NSURLSessionDataTask *)fetchPersonCapitalsByIdentifier:(NSUInteger)personIdentifier
                                       withPaginationInfo:(NBPaginationInfo *)paginationInfo
                                        completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    return [self fetchByResourceSubPath:[NSString stringWithFormat:@"/people/%lu/capitals", (unsigned long)personIdentifier]
                         withParameters:nil customResultsKey:nil paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)createPersonCapitalByIdentifier:(NSUInteger)personIdentifier
                                          withCapitalInfo:(NSDictionary *)capitalInfo
                                        completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    return [self createByResourceSubPath:[NSString stringWithFormat:@"/people/%lu/capitals", (unsigned long)personIdentifier]
                          withParameters:@{ @"capital": capitalInfo } resultsKey:@"capital" completionHandler:completionHandler];
}

// TODO: Deprecate to use NBClientEmptyCompletionHandler.
- (NSURLSessionDataTask *)deletePersonCapitalByPersonIdentifier:(NSUInteger)personIdentifier
                                              capitalIdentifier:(NSUInteger)capitalIdentifier
                                          withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    return [self deleteByResourceSubPath:[NSString stringWithFormat:@"/people/%lu/capitals/%lu", (unsigned long)personIdentifier, (unsigned long)capitalIdentifier]
                          withParameters:nil resultsKey:nil completionHandler:completionHandler];
}

#pragma mark - Notes

- (NSURLSessionDataTask *)createPersonPrivateNoteByIdentifier:(NSUInteger)personIdentifier
                                                 withNoteInfo:(NSDictionary *)noteInfo
                                            completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    return [self createByResourceSubPath:[NSString stringWithFormat:@"/people/%lu/notes", (unsigned long)personIdentifier]
                          withParameters:@{ @"note": noteInfo } resultsKey:@"note" completionHandler:completionHandler];
}

#pragma mark - Updating

- (NSURLSessionDataTask *)createPersonWithParameters:(NSDictionary *)parameters
                                   completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    return [self createByResourceSubPath:@"/people" withParameters:@{ @"person": parameters } resultsKey:@"person" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)savePersonByIdentifier:(NSUInteger)identifier
                                  withParameters:(NSDictionary *)parameters
                               completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    return [self saveByResourceSubPath:[NSString stringWithFormat:@"/people/%lu", (unsigned long)identifier]
                        withParameters:@{ @"person": parameters } resultsKey:@"person" completionHandler:completionHandler];
}

// TODO: Deprecate to use NBClientEmptyCompletionHandler.
- (NSURLSessionDataTask *)deletePersonByIdentifier:(NSUInteger)identifier
                             withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    return [self deleteByResourceSubPath:[NSString stringWithFormat:@"/people/%lu", (unsigned long)identifier]
                          withParameters:nil resultsKey:nil completionHandler:completionHandler];
}

@end
