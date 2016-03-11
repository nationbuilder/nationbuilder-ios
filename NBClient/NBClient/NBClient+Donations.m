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
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:@"/donations"];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"results" paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)createDonationWithParameters:(NSDictionary *)parameters
                                     completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:@"/donations"];
    return [self baseCreateTaskWithURL:components.URL parameters:@{ @"donation": parameters } resultsKey:@"donation" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)saveDonationByIdentifier:(NSUInteger)identifier
                                    withParameters:(NSDictionary *)parameters
                                 completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/donations/%lu", (unsigned long)identifier]];
    return [self baseSaveTaskWithURL:components.URL parameters:@{ @"donation": parameters } resultsKey:@"donation" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)deleteDonationByIdentifier:(NSUInteger)identifier
                                   completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/donations/%lu", (unsigned long)identifier]];
    return [self baseDeleteTaskWithURL:components.URL completionHandler:completionHandler];
}

@end
