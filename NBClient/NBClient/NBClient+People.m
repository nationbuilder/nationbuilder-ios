//
//  NBClient+People.m
//  NBClient
//
//  Created by Peng Wang on 7/21/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBClient+People.h"
#import "NBClient_Internal.h"

#import "FoundationAdditions.h"
#import "NBPaginationInfo.h"

@implementation NBClient (People)

- (NSURLSessionDataTask *)fetchPeopleWithPaginationInfo:(NBPaginationInfo *)paginationInfo
                                      completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    NSURLComponents *components = self.baseURLComponents.copy;
    components.path = [components.path stringByAppendingString:@"/people"];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"results" paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchPeopleByParameters:(NSDictionary *)parameters
                               withPaginationInfo:(NBPaginationInfo *)paginationInfo
                                completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    NSURLComponents *components = self.baseURLComponents.copy;
    components.path = [components.path stringByAppendingString:@"/people/search"];
    components.query = [components.query stringByAppendingFormat:@"&%@",
                        [parameters nb_queryStringWithEncoding:NSASCIIStringEncoding
                                   skipPercentEncodingPairKeys:nil charactersToLeaveUnescaped:nil]];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"results" paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchPersonByIdentifier:(NSUInteger)identifier
                            withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = self.baseURLComponents.copy;
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/people/%d", identifier]];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"person" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchPersonByParameters:(NSDictionary *)parameters
                            withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = self.baseURLComponents.copy;
    components.path = [components.path stringByAppendingString:@"/people/match"];
    components.query = [[parameters nb_queryStringWithEncoding:NSASCIIStringEncoding
                                   skipPercentEncodingPairKeys:[NSSet setWithObject:@"email"]
                                    charactersToLeaveUnescaped:nil]
                        stringByAppendingFormat:@"&%@", components.query];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"person" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)createPersonWithParameters:(NSDictionary *)parameters
                                   completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = self.baseURLComponents.copy;
    components.path = [components.path stringByAppendingString:@"/people"];
    NSError *error;
    NSMutableURLRequest *request = [self baseSaveRequestWithURL:components.URL parameters:@{ @"person": parameters } error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{ completionHandler(nil, error); });
        return nil;
    }
    request.HTTPMethod = @"POST";
    return [self baseSaveTaskWithURLRequest:request resultsKey:@"person" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)savePersonByIdentifier:(NSUInteger)identifier
                                  withParameters:(NSDictionary *)parameters
                               completionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = self.baseURLComponents.copy;
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/people/%d", identifier]];
    NSError *error;
    NSMutableURLRequest *request = [self baseSaveRequestWithURL:components.URL parameters:@{ @"person": parameters } error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{ completionHandler(nil, error); });
        return nil;
    }
    return [self baseSaveTaskWithURLRequest:request resultsKey:@"person" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)deletePersonByIdentifier:(NSUInteger)identifier
                             withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = self.baseURLComponents.copy;
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/people/%d", identifier]];
    return [self baseDeleteTaskWithURL:components.URL completionHandler:completionHandler];
}

@end
