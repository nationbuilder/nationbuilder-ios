//
//  NBClient+Donations.m
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBClient+Donations.h"
#import "NBClient_Internal.h"

#import "FoundationAdditions.h"
#import "NBPaginationInfo.h"

@implementation NBClient (Donations)

- (NSURLSessionDataTask *)fetchDonationsWithPaginationInfo:(NBPaginationInfo *)paginationInfo
                                         completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    return [self fetchByResourceSubPath:@"/donations" withParameters:nil customResultsKey:nil paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)createDonationWithParameters:(NSDictionary *)parameters
                                     completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    return [self createByResourceSubPath:@"/donations" withParameters:@{ @"donation": parameters } resultsKey:@"donation" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)saveDonationByIdentifier:(NSUInteger)identifier
                                    withParameters:(NSDictionary *)parameters
                                 completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    return [self saveByResourceSubPath:[NSString stringWithFormat:@"/donations/%lu", (unsigned long)identifier]
                        withParameters:@{ @"donation": parameters } resultsKey:@"donation" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)deleteDonationByIdentifier:(NSUInteger)identifier
                                   completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    return [self deleteByResourceSubPath:[NSString stringWithFormat:@"/donations/%lu", (unsigned long)identifier]
                          withParameters:nil resultsKey:nil completionHandler:completionHandler];
}

@end
