//
//  NBClient+Surveys.m
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBClient+Surveys.h"
#import "NBClient_Internal.h"

#import "FoundationAdditions.h"
#import "NBPaginationInfo.h"

@implementation NBClient (Surveys)

#pragma mark - (Site) Surveys

- (NSURLSessionDataTask *)fetchSurveysBySiteSlug:(NSString *)siteSlug
                              withPaginationInfo:(NBPaginationInfo *)paginationInfo
                               completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/sites/%@/pages/surveys", siteSlug]];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"results" paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)createSurveyBySiteSlug:(NSString *)siteSlug
                                  withParameters:(NSDictionary *)parameters
                               completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/sites/%@/pages/surveys", siteSlug]];
    return [self baseCreateTaskWithURL:components.URL parameters:@{ @"survey": parameters } resultsKey:@"survey" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)saveSurveyBySiteSlug:(NSString *)siteSlug
                                    identifier:(NSUInteger)identifier
                                withParameters:(NSDictionary *)parameters
                             completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/sites/%@/pages/surveys/%lu", siteSlug, (unsigned long)identifier]];
    return [self baseSaveTaskWithURL:components.URL parameters:@{ @"survey": parameters } resultsKey:@"survey" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)deleteSurveyBySiteSlug:(NSString *)siteSlug
                                      identifier:(NSUInteger)identifier
                               completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/sites/%@/pages/surveys/%lu", siteSlug, (unsigned long)identifier]];
    return [self baseDeleteTaskWithURL:components.URL completionHandler:completionHandler];
}

#pragma mark - Survey Responses

- (NSURLSessionDataTask *)fetchSurveyResponseByIdentifier:(NSUInteger)surveyIdentifier
                                               parameters:(NSDictionary *)parameters
                                       withPaginationInfo:(NBPaginationInfo *)paginationInfo
                                        completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:@"/survey_responses"];
    NSMutableDictionary *mutableParameters = [components.percentEncodedQuery nb_queryStringParameters].mutableCopy;
    mutableParameters[@"survey_id"] = @(surveyIdentifier);
    if (parameters) {
        [mutableParameters addEntriesFromDictionary:parameters];
    }
    components.percentEncodedQuery = [mutableParameters nb_queryString];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"results" paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)createSurveyResponseByIdentifier:(NSUInteger)surveyIdentifier
                                            withParameters:(NSDictionary *)parameters
                                         completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    NSMutableDictionary *mutableParameters = parameters.mutableCopy;
    mutableParameters[@"survey_id"] = @(surveyIdentifier);
    components.path = [components.path stringByAppendingString:@"/survey_responses"];
    return [self baseCreateTaskWithURL:components.URL parameters:@{ @"survey_response": mutableParameters } resultsKey:@"survey_response" completionHandler:completionHandler];

}

@end
