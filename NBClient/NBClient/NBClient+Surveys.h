//
//  NBClient+Surveys.h
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBClient.h"

@interface NBClient (Surveys)

/**
 Surveys & Responses
 
 The endpoint annotations are for reference only to link to the API docs and may
 change independently of the method selectors below.
 
 The order of the methods listing attempts to mirror that of apiexplorer.nationbuilder.com.
 */

#pragma mark - (Site) Surveys

// GET /sites/:slug/pages/surveys
- (nonnull NSURLSessionDataTask *)fetchSurveysBySiteSlug:(nonnull NSString *)siteSlug
                                      withPaginationInfo:(nullable NBPaginationInfo *)paginationInfo
                                       completionHandler:(nonnull NBClientResourceListCompletionHandler)completionHandler;

// POST /sites/:slug/pages/surveys
- (nullable NSURLSessionDataTask *)createSurveyBySiteSlug:(nonnull NSString *)siteSlug
                                           withParameters:(nonnull NSDictionary *)parameters
                                        completionHandler:(nonnull NBClientResourceItemCompletionHandler)completionHandler;

// PUT /sites/:slug/pages/surveys/:id
- (nullable NSURLSessionDataTask *)saveSurveyBySiteSlug:(nonnull NSString *)siteSlug
                                             identifier:(NSUInteger)identifier
                                         withParameters:(nonnull NSDictionary *)parameters
                                      completionHandler:(nonnull NBClientResourceItemCompletionHandler)completionHandler;

// DELETE /sites/:slug/pages/surveys/:id
- (nonnull NSURLSessionDataTask *)deleteSurveyBySiteSlug:(nonnull NSString *)siteSlug
                                              identifier:(NSUInteger)identifier
                                       completionHandler:(nonnull NBClientResourceItemCompletionHandler)completionHandler;

#pragma mark - Survey Responses

// GET /survey_responses
- (nonnull NSURLSessionDataTask *)fetchSurveyResponseByIdentifier:(NSUInteger)surveyIdentifier
                                                       parameters:(nullable NSDictionary *)parameters
                                               withPaginationInfo:(nullable NBPaginationInfo *)paginationInfo
                                                completionHandler:(nonnull NBClientResourceListCompletionHandler)completionHandler;

// POST /survey_responses
- (nullable NSURLSessionDataTask *)createSurveyResponseByIdentifier:(NSUInteger)surveyIdentifier
                                                     withParameters:(nonnull NSDictionary *)parameters
                                                  completionHandler:(nonnull NBClientResourceItemCompletionHandler)completionHandler;

@end
