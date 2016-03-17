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
    return [self fetchByResourceSubPath:@"/tags" withParameters:nil customResultsKey:nil paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchTagPeopleByName:(NSString *)tagName
                            withPaginationInfo:(NBPaginationInfo *)paginationInfo
                             completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    return [self fetchByResourceSubPath:[NSString stringWithFormat:@"/tags/%@/people", tagName]
                         withParameters:nil customResultsKey:nil paginationInfo:paginationInfo completionHandler:completionHandler];
}

@end
