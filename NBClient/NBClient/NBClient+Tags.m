//
//  NBClient+Tags.m
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBClient+Tags.h"
#import "NBClient_Internal.h"

#import "FoundationAdditions.h"
#import "NBPaginationInfo.h"

@implementation NBClient (Tags)

- (NSURLSessionDataTask *)fetchTagsWithPaginationInfo:(NBPaginationInfo *)paginationInfo
                                    completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:@"/tags"];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"results" paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchTagPeopleByName:(NSString *)tagName
                            withPaginationInfo:(NBPaginationInfo *)paginationInfo
                             completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    NSURLComponents *components = [self.baseURLComponents copy];
    components.path = [components.path stringByAppendingString:[NSString stringWithFormat:@"/tags/%@/people", tagName]];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"results" paginationInfo:paginationInfo completionHandler:completionHandler];
}

@end
