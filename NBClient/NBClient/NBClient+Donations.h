//
//  NBClient+Donations.h
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBClient.h"

@interface NBClient (Donations)

/**
 Donations
 
 The endpoint annotations are for reference only to link to the API docs and may
 change independently of the method selectors below.
 
 The order of the methods listing attempts to mirror that of apiexplorer.nationbuilder.com.
 */

// GET /donations
- (nonnull NSURLSessionDataTask *)fetchDonationsWithPaginationInfo:(nullable NBPaginationInfo *)paginationInfo
                                                 completionHandler:(nonnull NBClientResourceListCompletionHandler)completionHandler;

// POST /donations
- (nullable NSURLSessionDataTask *)createDonationWithParameters:(nonnull NSDictionary *)parameters
                                              completionHandler:(nonnull NBClientResourceItemCompletionHandler)completionHandler;

// PUT /donation/:id
- (nullable NSURLSessionDataTask *)saveDonationByIdentifier:(NSUInteger)identifier
                                             withParameters:(nonnull NSDictionary *)parameters
                                          completionHandler:(nonnull NBClientResourceItemCompletionHandler)completionHandler;

// DELETE /donation/:id
- (nonnull NSURLSessionDataTask *)deleteDonationByIdentifier:(NSUInteger)identifier
                                           completionHandler:(nonnull NBClientResourceItemCompletionHandler)completionHandler;

@end
