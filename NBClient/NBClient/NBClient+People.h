//
//  NBClient+People.h
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import "NBClient.h"

@interface NBClient (People)

/**
 People
 
 The endpoint annotations are for reference only to link to the API docs and may
 change independently of the method selectors below.
 
 The order of the methods listing attempts to mirror that of apiexplorer.nationbuilder.com.
 */

// GET /people
- (NSURLSessionDataTask *)fetchPeopleWithPaginationInfo:(NBPaginationInfo *)paginationInfo
                                      completionHandler:(NBClientResourceListCompletionHandler)completionHandler;
// GET /people/:id
- (NSURLSessionDataTask *)fetchPersonByIdentifier:(NSUInteger)identifier
                            withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler;
// GET /people/search
- (NSURLSessionDataTask *)fetchPeopleByParameters:(NSDictionary *)parameters
                               withPaginationInfo:(NBPaginationInfo *)paginationInfo
                                completionHandler:(NBClientResourceListCompletionHandler)completionHandler;
// GET /people/nearby
- (NSURLSessionDataTask *)fetchPeopleNearbyByLocationInfo:(NSDictionary *)locationInfo
                                       withPaginationInfo:(NBPaginationInfo *)paginationInfo
                                        completionHandler:(NBClientResourceListCompletionHandler)completionHandler;
// GET /people/me
- (NSURLSessionDataTask *)fetchPersonForClientUserWithCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler;
// GET /people/:id/register
- (NSURLSessionDataTask *)registerPersonByIdentifier:(NSUInteger)identifier
                               withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler;
// GET /people/match
- (NSURLSessionDataTask *)fetchPersonByParameters:(NSDictionary *)parameters
                            withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler;
// GET /people/:id/taggings
- (NSURLSessionDataTask *)fetchPersonTaggingsByIdentifier:(NSUInteger)personIdentifier
                                    withCompletionHandler:(NBClientResourceListCompletionHandler)completionHandler;
// PUT /people/:id/taggings
- (NSURLSessionDataTask *)createPersonTaggingByIdentifier:(NSUInteger)personIdentifier
                                          withTaggingInfo:(NSDictionary *)taggingInfo
                                        completionHandler:(NBClientResourceItemCompletionHandler)completionHandler;
- (NSURLSessionDataTask *)createPersonTaggingsByIdentifier:(NSUInteger)personIdentifier
                                           withTaggingInfo:(NSDictionary *)taggingInfo
                                         completionHandler:(NBClientResourceListCompletionHandler)completionHandler;
// DELETE /people/:id/taggings/:tag
- (NSURLSessionDataTask *)deletePersonTaggingsByIdentifier:(NSUInteger)personIdentifier
                                                  tagNames:(NSArray *)tagNames
                                     withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler;
// POST /people
- (NSURLSessionDataTask *)createPersonWithParameters:(NSDictionary *)parameters
                                   completionHandler:(NBClientResourceItemCompletionHandler)completionHandler;
// PUT /people/:id
- (NSURLSessionDataTask *)savePersonByIdentifier:(NSUInteger)identifier
                                  withParameters:(NSDictionary *)parameters
                               completionHandler:(NBClientResourceItemCompletionHandler)completionHandler;
// DELETE /people/:id
- (NSURLSessionDataTask *)deletePersonByIdentifier:(NSUInteger)identifier
                             withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler;


@end
