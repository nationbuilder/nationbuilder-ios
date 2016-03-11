//
//  NBClient+People.m
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import "NBClient+People.h"
#import "NBClient_Internal.h"

#import "FoundationAdditions.h"
#import "NBPaginationInfo.h"

@implementation NBClient (People)

#pragma mark - Fetch

- (NSURLSessionDataTask *)fetchPeopleWithPaginationInfo:(NBPaginationInfo *)paginationInfo
                                      completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:@"/people"];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"results" paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchPeopleCountWithCompletionHandler:(NBClientResourceCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:@"/people/count"];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"people_count" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchPersonByIdentifier:(NSUInteger)identifier
                            withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/people/%lu", (unsigned long)identifier]];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"person" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchPeopleByParameters:(NSDictionary *)parameters
                               withPaginationInfo:(NBPaginationInfo *)paginationInfo
                                completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:@"/people/search"];
    NSMutableDictionary *mutableParameters = [parameters mutableCopy];
    [mutableParameters addEntriesFromDictionary:[components.percentEncodedQuery nb_queryStringParameters]];
    components.percentEncodedQuery = [mutableParameters nb_queryString];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"results" paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchPeopleNearbyByLocationInfo:(NSDictionary *)locationInfo
                                       withPaginationInfo:(NBPaginationInfo *)paginationInfo
                                        completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:@"/people/nearby"];
    NSMutableDictionary *mutableParameters = [[components.percentEncodedQuery nb_queryStringParameters] mutableCopy];
    mutableParameters[@"location"] = [NSString stringWithFormat:@"%@,%@", locationInfo[NBClientLocationLatitudeKey], locationInfo[NBClientLocationLongitudeKey]];
    mutableParameters[@"distance"] = !locationInfo[NBClientLocationProximityDistanceKey] ? @1 : locationInfo[NBClientLocationProximityDistanceKey];
    components.percentEncodedQuery = [mutableParameters nb_queryString];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"results" paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchPersonForClientUserWithCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:@"/people/me"];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"person" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)registerPersonByIdentifier:(NSUInteger)identifier
                               withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/people/%lu/register", (unsigned long)identifier]];
    return [self baseFetchTaskWithURLComponents:components resultsKey:nil completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchPersonByParameters:(NSDictionary *)parameters
                            withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:@"/people/match"];
    NSMutableDictionary *mutableParameters = [parameters mutableCopy];
    [mutableParameters addEntriesFromDictionary:[components.percentEncodedQuery nb_queryStringParameters]];
    components.percentEncodedQuery = [mutableParameters nb_queryString];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"person" completionHandler:completionHandler];
}

#pragma mark - Taggings

- (NSURLSessionDataTask *)fetchPersonTaggingsByIdentifier:(NSUInteger)personIdentifier
                                    withCompletionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/people/%lu/taggings", (unsigned long)personIdentifier]];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"taggings" paginationInfo:nil completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)createPersonTaggingByIdentifier:(NSUInteger)personIdentifier
                                          withTaggingInfo:(NSDictionary *)taggingInfo
                                        completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/people/%lu/taggings", (unsigned long)personIdentifier]];
    return [self baseSaveTaskWithURL:components.URL parameters:@{ @"tagging": taggingInfo } resultsKey:@"tagging" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)createPersonTaggingsByIdentifier:(NSUInteger)personIdentifier
                                           withTaggingInfo:(NSDictionary *)taggingInfo
                                         completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/people/%lu/taggings", (unsigned long)personIdentifier]];
    NSError *error;
    NSMutableURLRequest *request = [self baseRequestWithURL:components.URL parameters:@{ @"tagging": taggingInfo } error:&error];
    request.HTTPMethod = @"PUT";
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{ completionHandler(nil, nil, error); });
        return nil;
    }
    return [self baseSaveTaskWithURLRequest:request resultsKey:@"taggings" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)deletePersonTaggingsByIdentifier:(NSUInteger)personIdentifier
                                                  tagNames:(NSArray *)tagNames
                                     withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/people/%lu/taggings", (unsigned long)personIdentifier]];
    BOOL isBulk = tagNames.count > 1;
    if (isBulk) {
        return [self baseDeleteTaskWithURL:components.URL parameters:@{ @"tagging": @{ NBClientTaggingTagNameOrListKey: tagNames } } resultsKey:nil completionHandler:completionHandler];
    }
    // Use the non-bulk endpoint if we can.
    components.path = [components.path stringByAppendingPathComponent:tagNames.firstObject];
    return [self baseDeleteTaskWithURL:components.URL completionHandler:completionHandler];
}

#pragma mark - Political Capital

- (NSURLSessionDataTask *)fetchPersonCapitalsByIdentifier:(NSUInteger)personIdentifier
                                       withPaginationInfo:(NBPaginationInfo *)paginationInfo
                                        completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/people/%lu/capitals", (unsigned long)personIdentifier]];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"results" paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)createPersonCapitalByIdentifier:(NSUInteger)personIdentifier
                                          withCapitalInfo:(NSDictionary *)capitalInfo
                                        completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/people/%lu/capitals", (unsigned long)personIdentifier]];
    return [self baseCreateTaskWithURL:components.URL parameters:@{ @"capital": capitalInfo } resultsKey:@"capital" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)deletePersonCapitalByPersonIdentifier:(NSUInteger)personIdentifier
                                              capitalIdentifier:(NSUInteger)capitalIdentifier
                                          withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/people/%lu/capitals/%lu",
                        (unsigned long)personIdentifier, (unsigned long)capitalIdentifier]];
    return [self baseDeleteTaskWithURL:components.URL completionHandler:completionHandler];
}

#pragma mark - Notes

- (NSURLSessionDataTask *)createPersonPrivateNoteByIdentifier:(NSUInteger)personIdentifier
                                                 withNoteInfo:(NSDictionary *)noteInfo
                                            completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/people/%lu/notes", (unsigned long)personIdentifier]];
    return [self baseCreateTaskWithURL:components.URL parameters:@{ @"note": noteInfo } resultsKey:@"note" completionHandler:completionHandler];
}

#pragma mark - Updating

- (NSURLSessionDataTask *)createPersonWithParameters:(NSDictionary *)parameters
                                   completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:@"/people"];
    return [self baseCreateTaskWithURL:components.URL parameters:@{ @"person": parameters } resultsKey:@"person" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)savePersonByIdentifier:(NSUInteger)identifier
                                  withParameters:(NSDictionary *)parameters
                               completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/people/%lu", (unsigned long)identifier]];
    return [self baseSaveTaskWithURL:components.URL parameters:@{ @"person": parameters } resultsKey:@"person" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)deletePersonByIdentifier:(NSUInteger)identifier
                             withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/people/%lu", (unsigned long)identifier]];
    return [self baseDeleteTaskWithURL:components.URL completionHandler:completionHandler];
}

@end
