//
//  NBClient+Sites.h
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBClient.h"

@interface NBClient (Sites)

/**
 Sites (Fetch Only)
 
 The endpoint annotations are for reference only to link to the API docs and may
 change independently of the method selectors below.
 
 The order of the methods listing attempts to mirror that of apiexplorer.nationbuilder.com.
 */

// GET /sites
- (nonnull NSURLSessionDataTask *)fetchSitesWithPaginationInfo:(nullable NBPaginationInfo *)paginationInfo
                                             completionHandler:(nonnull NBClientResourceListCompletionHandler)completionHandler;

@end
