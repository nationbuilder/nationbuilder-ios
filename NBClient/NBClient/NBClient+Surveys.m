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
    return [self fetchByResourceSubPath:[NSString stringWithFormat:@"/sites/%@/pages/surveys", siteSlug]
                         withParameters:nil customResultsKey:nil paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)createSurveyBySiteSlug:(NSString *)siteSlug
                                  withParameters:(NSDictionary *)parameters
                               completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    return [self createByResourceSubPath:[NSString stringWithFormat:@"/sites/%@/pages/surveys", siteSlug]
                          withParameters:@{ @"survey": parameters } resultsKey:@"survey" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)saveSurveyBySiteSlug:(NSString *)siteSlug
                                    identifier:(NSUInteger)identifier
                                withParameters:(NSDictionary *)parameters
                             completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    return [self saveByResourceSubPath:[NSString stringWithFormat:@"/sites/%@/pages/surveys/%lu", siteSlug, (unsigned long)identifier]
                        withParameters:@{ @"survey": parameters } resultsKey:@"survey" completionHandler:completionHandler];
}

// TODO: Deprecate to use NBClientEmptyCompletionHandler.
- (NSURLSessionDataTask *)deleteSurveyBySiteSlug:(NSString *)siteSlug
                                      identifier:(NSUInteger)identifier
                               completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    return [self deleteByResourceSubPath:[NSString stringWithFormat:@"/sites/%@/pages/surveys/%lu", siteSlug, (unsigned long)identifier]
                          withParameters:nil resultsKey:nil completionHandler:completionHandler];
}

#pragma mark - Survey Responses

- (NSURLSessionDataTask *)fetchSurveyResponseByIdentifier:(NSUInteger)surveyIdentifier
                                               parameters:(NSDictionary *)parameters
                                       withPaginationInfo:(NBPaginationInfo *)paginationInfo
                                        completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    parameters = parameters ?: @{};
    NSMutableDictionary *mutableParameters = parameters.mutableCopy;
    mutableParameters[@"survey_id"] = @(surveyIdentifier);
    return [self fetchByResourceSubPath:@"/survey_responses" withParameters:mutableParameters customResultsKey:nil paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)createSurveyResponseByIdentifier:(NSUInteger)surveyIdentifier
                                            withParameters:(NSDictionary *)parameters
                                         completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSMutableDictionary *mutableParameters = parameters.mutableCopy;
    mutableParameters[@"survey_id"] = @(surveyIdentifier);
    return [self createByResourceSubPath:@"/survey_responses" withParameters:@{ @"survey_response": mutableParameters }
                              resultsKey:@"survey_response" completionHandler:completionHandler];
}

@end
