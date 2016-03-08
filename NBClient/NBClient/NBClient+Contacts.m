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

- (NSURLSessionDataTask *)fetchPersonContactsByIdentifier:(NSUInteger)personIdentifier
                                       withPaginationInfo:(NBPaginationInfo *)paginationInfo
                                        completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/people/%lu/contacts", (unsigned long)personIdentifier]];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"results" paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)createPersonContactByIdentifier:(NSUInteger)personIdentifier
                                          withContactInfo:(NSDictionary *)contactInfo
                                        completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/people/%lu/contacts", (unsigned long)personIdentifier]];
    return [self baseCreateTaskWithURL:components.URL parameters:@{ @"contact": contactInfo } resultsKey:@"contact" completionHandler:completionHandler];
}

@end
