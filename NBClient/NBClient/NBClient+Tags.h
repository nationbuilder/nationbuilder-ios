//
//  NBClient+Tags.h
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBClient.h"

@interface NBClient (Tags)

/**
 Tags
 
 The endpoint annotations are for reference only to link to the API docs and may
 change independently of the method selectors below.
 
 The order of the methods listing attempts to mirror that of apiexplorer.nationbuilder.com.
 */

// GET /tags
- (nonnull NSURLSessionDataTask *)fetchTagsWithPaginationInfo:(nullable NBPaginationInfo *)paginationInfo
                                            completionHandler:(nonnull NBClientResourceListCompletionHandler)completionHandler;

// GET /tags/:id/people
- (nonnull NSURLSessionDataTask *)fetchTagPeopleByName:(nonnull NSString *)tagName
                                    withPaginationInfo:(nullable NBPaginationInfo *)paginationInfo
                                     completionHandler:(nonnull NBClientResourceListCompletionHandler)completionHandler;

@end
