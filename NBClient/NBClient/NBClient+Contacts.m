//
//  NBClient+Contacts.m
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBClient+Contacts.h"
#import "NBClient_Internal.h"

#import "FoundationAdditions.h"
#import "NBPaginationInfo.h"

@implementation NBClient (Contacts)

#pragma mark - Contacts

- (NSURLSessionDataTask *)fetchPersonContactsByIdentifier:(NSUInteger)personIdentifier
                                       withPaginationInfo:(NBPaginationInfo *)paginationInfo
                                        completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    return [self fetchByResourceSubPath:[NSString stringWithFormat:@"/people/%lu/contacts", (unsigned long)personIdentifier]
                  withParameters:nil customResultsKey:nil paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)createPersonContactByIdentifier:(NSUInteger)personIdentifier
                                          withContactInfo:(NSDictionary *)contactInfo
                                        completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    return [self createByResourceSubPath:[NSString stringWithFormat:@"/people/%lu/contacts", (unsigned long)personIdentifier]
                          withParameters:@{ @"contact": contactInfo } resultsKey:@"contact" completionHandler:completionHandler];
}

#pragma mark - Contact Types (Fetch Only)

- (NSURLSessionDataTask *)fetchContactTypesWithPaginationInfo:(NBPaginationInfo *)paginationInfo
                                            completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    return [self fetchByResourceSubPath:@"/settings/contact_types" withParameters:nil customResultsKey:nil paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchContactMethodsWithCompletionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    return [self fetchByResourceSubPath:@"/settings/contact_methods" withParameters:nil customResultsKey:nil paginationInfo:nil completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchContactStatusesWithCompletionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    return [self fetchByResourceSubPath:@"/settings/contact_statuses" withParameters:nil customResultsKey:nil paginationInfo:nil completionHandler:completionHandler];
}

@end
