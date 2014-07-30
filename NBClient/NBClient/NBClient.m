//
//  NBClient.m
//  NBClient
//
//  Created by Peng Wang on 7/8/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBClient.h"
#import "NBClient_Internal.h"

#import "NBAuthenticator.h"
#import "NBDefines.h"
#import "FoundationAdditions.h"
#import "NBPaginationInfo.h"

NSUInteger const NBClientErrorCodeService = 1;
NSString * const NBClientErrorCodeKey = @"code";
NSString * const NBClientErrorMessageKey = @"message";
NSString * const NBClientErrorValidationErrorsKey = @"validation_errors";
NSString * const NBClientErrorInnerErrorKey = @"inner_error";

@implementation NBClient

#pragma mark - Initializers

- (instancetype)initWithNationName:(NSString *)nationName
                     authenticator:(NBAuthenticator *)authenticator
                  customURLSession:(NSURLSession *)urlSession
     customURLSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration
{
    self = [super init];
    if (self) {
        [self commonInitWithNationName:nationName customURLSession:urlSession customURLSessionConfiguration:sessionConfiguration];
        self.authenticator = authenticator;
    }
    return self;
}

- (instancetype)initWithNationName:(NSString *)nationName
                            apiKey:(NSString *)apiKey
                     customBaseURL:(NSURL *)baseURL
                  customURLSession:(NSURLSession *)urlSession
     customURLSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration
{
    self = [super init];
    if (self) {
        [self commonInitWithNationName:nationName customURLSession:urlSession customURLSessionConfiguration:sessionConfiguration];
        self.apiKey = apiKey;
        self.baseURL = baseURL;
    }
    return self;
}

- (void)commonInitWithNationName:(NSString *)nationName
                customURLSession:(NSURLSession *)urlSession
   customURLSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration
{
    self.nationName = nationName;
    self.urlSession = urlSession;
    self.sessionConfiguration = sessionConfiguration;
    
    self.defaultErrorRecoverySuggestion = NSLocalizedString(@"If failure reasion is not helpful, "
                                                            @"contact NationBuilder for support.", nil);
}

#pragma mark - Private

#pragma mark Accessors

- (NSURLSessionConfiguration *)sessionConfiguration
{
    static NSURLCache *sharedCache;
    BOOL shouldUseDefaultCache = !_sessionConfiguration || !_sessionConfiguration.URLCache;
    if (shouldUseDefaultCache) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            const NSUInteger mb = 1024 * 1024;
            NSString *desiredApplicationSubdirectoryPath = self.baseURL.host;
            sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * mb
                                                        diskCapacity:20 * mb
                                                            diskPath:desiredApplicationSubdirectoryPath];
        });
    }
    if (!_sessionConfiguration) {
        self.sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    }
    if (shouldUseDefaultCache) {
        _sessionConfiguration.URLCache = sharedCache;
    }
    return _sessionConfiguration;
}

- (NSURLSession *)urlSession
{
    if (_urlSession) {
        return _urlSession;
    }
    self.urlSession = [NSURLSession sessionWithConfiguration:self.sessionConfiguration
                                                    delegate:self
                                               delegateQueue:[NSOperationQueue mainQueue]];
    return _urlSession;
}

#pragma mark Requests & Tasks

- (NSURL *)baseURL
{
    if (_baseURL) {
        return _baseURL;
    }
    self.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.nationbuilder.com", self.nationName]];
    return _baseURL;
}

- (NSURLComponents *)baseURLComponents
{
    if (_baseURLComponents) {
        return _baseURLComponents;
    }
    self.baseURLComponents = [NSURLComponents componentsWithURL:self.baseURL resolvingAgainstBaseURL:YES];
    NSDictionary *queryParameters = @{ @"access_token": self.apiKey };
    _baseURLComponents.path = @"/api/v1";
    _baseURLComponents.query = [queryParameters nb_queryStringWithEncoding:NSASCIIStringEncoding
                                               skipPercentEncodingPairKeys:nil charactersToLeaveUnescaped:nil];
    return _baseURLComponents;
}

- (NSMutableURLRequest *)baseFetchRequestWithURL:(NSURL *)url
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadRevalidatingCacheData
                                                       timeoutInterval:10.0f];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    return request;
}

- (NSURLSessionDataTask *)baseFetchTaskWithURLComponents:(NSURLComponents *)components
                                              resultsKey:(NSString *)resultsKey
                                          paginationInfo:(NBPaginationInfo *__autoreleasing *)paginationInfo
                                       completionHandler:(void (^)(id, NSError *))completionHandler
{
    if (paginationInfo && *paginationInfo) {
        components.query = [components.query stringByAppendingFormat:@"&%@",
                            [(*paginationInfo).dictionary nb_queryStringWithEncoding:NSASCIIStringEncoding
                                                         skipPercentEncodingPairKeys:nil charactersToLeaveUnescaped:nil]];
    }
    NSURLSessionDataTask *task =
    [self.urlSession
     dataTaskWithRequest:[self baseFetchRequestWithURL:components.URL]
     completionHandler:[self dataTaskCompletionHandlerForFetchResultsKey:resultsKey completionHandler:^(id results, NSDictionary *jsonObject, NSError *error) {
        if (paginationInfo) { // If pointer is non-NULL.
            *paginationInfo = [[NBPaginationInfo alloc] initWithDictionary:jsonObject];
        }
        if (completionHandler) {
            completionHandler(results, error);
        }
    }]];
    return [self startTask:task];
}

- (NSMutableURLRequest *)baseSaveRequestWithURL:(NSURL *)url
                                     parameters:(NSDictionary *)parameters
                                          error:(NSError *__autoreleasing *)error
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0f];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"PUT"; // Overwrite as needed.
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:parameters options:0 error:error]];
    return request;
}

- (NSURLSessionDataTask *)baseSaveTaskWithURLRequest:(NSURLRequest *)request
                                          resultsKey:(NSString *)resultsKey
                                   completionHandler:(void (^)(id, NSError *))completionHandler
{
    NSURLSessionDataTask *task =
    [self.urlSession
     dataTaskWithRequest:request
     completionHandler:[self dataTaskCompletionHandlerForFetchResultsKey:resultsKey completionHandler:^(id results, NSDictionary *jsonObject, NSError *error) {
        if (completionHandler) {
            completionHandler(results, error);
        }
    }]];
    return [self startTask:task];
}

- (NSMutableURLRequest *)baseDeleteRequestWithURL:(NSURL *)url
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0f];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    request.HTTPMethod = @"DELETE";
    return request;
}

- (NSURLSessionDataTask *)baseDeleteTaskWithURL:(NSURL *)url
                              completionHandler:(void (^)(id, NSError *))completionHandler
{
    NSURLSessionDataTask *task =
    [self.urlSession
     dataTaskWithRequest:[self baseDeleteRequestWithURL:url]
     completionHandler:[self dataTaskCompletionHandlerForFetchResultsKey:nil completionHandler:^(id results, NSDictionary *jsonObject, NSError *error) {
        if (completionHandler) {
            completionHandler(results, error);
        }
    }]];
    return [self startTask:task];
}

- (NSURLSessionDataTask *)startTask:(NSURLSessionDataTask *)task
{
    [task resume];
    return task;
}

#pragma mark Handlers

- (void (^)(NSData *, NSURLResponse *, NSError *))dataTaskCompletionHandlerForFetchResultsKey:(NSString *)resultsKey
                                                                            completionHandler:(void (^)(id, NSDictionary *, NSError *))completionHandler
{
    return ^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (data) {
            [self logResponse:httpResponse data:data];
        }
        // Handle data task error.
        if (error) {
            if (completionHandler) {
                completionHandler(nil, nil, error);
            }
            return;
        }
        // Handle empty bodies.
        if ([[NSIndexSet nb_indexSetOfSuccessfulEmptyResponseHTTPStatusCodes] containsIndex:httpResponse.statusCode]) {
            if (completionHandler) {
                completionHandler(nil, nil, error);
            }
            return;
        }
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingAllowFragments
                                                                     error:&error];
        // Handle HTTP error.
        if (![[NSIndexSet nb_indexSetOfSuccessfulHTTPStatusCodes] containsIndex:httpResponse.statusCode]) {
            error = [self errorForResponse:httpResponse jsonData:jsonObject];
            if (completionHandler) {
                completionHandler(nil, nil, error);
            }
            return;
        }
        // Handle JSON error.
        if (error) {
            if (completionHandler) {
                completionHandler(nil, nil, error);
            }
            return;
        }
        // Handle Non-HTTP error.
        if (jsonObject[@"code"]) {
            error = [self errorForResponse:httpResponse jsonData:jsonObject];
        }
        id results = jsonObject[resultsKey];
        // Handle invalid response.
        if (!results) {
            error = [self errorForJsonData:jsonObject resultsKey:resultsKey];
        }
        if (completionHandler) {
            completionHandler(results, jsonObject, error);
        }
    };
}

#pragma mark Helpers

- (NSError *)errorForResponse:(NSHTTPURLResponse *)response
                     jsonData:(NSDictionary *)data
{
    NSString *description;
    if ([[NSIndexSet nb_indexSetOfSuccessfulHTTPStatusCodes] containsIndex:response.statusCode]) {
        description = [NSString localizedStringWithFormat:
                       NSLocalizedString(@"Service errored fulfilling request, code: %@", nil),
                       data[@"code"]];
    } else {
        description = [NSString localizedStringWithFormat:
                       NSLocalizedString(@"Service errored fulfilling request, status code: %d (%@)", nil),
                       response.statusCode, data[@"code"]];
    }
    return [NSError
            errorWithDomain:NBErrorDomain
            code:NBClientErrorCodeService
            userInfo:@{ NSLocalizedDescriptionKey: description,
                        NSLocalizedFailureReasonErrorKey: NSLocalizedString(data[@"message"] ? data[@"message"] : @"Reason unknown.", nil),
                        NSLocalizedRecoverySuggestionErrorKey: self.defaultErrorRecoverySuggestion,
                        NBClientErrorCodeKey: (data[NBClientErrorCodeKey] ? data[NBClientErrorCodeKey] : @""),
                        NBClientErrorMessageKey: (data[NBClientErrorMessageKey] ? data[NBClientErrorMessageKey] : @""),
                        NBClientErrorValidationErrorsKey: (data[NBClientErrorValidationErrorsKey] ? data[NBClientErrorValidationErrorsKey] : @[]),
                        NBClientErrorInnerErrorKey: (data[NBClientErrorInnerErrorKey] ? data[NBClientErrorInnerErrorKey] : @{}) }];
}

- (NSError *)errorForJsonData:(NSDictionary *)data
                   resultsKey:(NSString *)resultsKey
{
    return [NSError
            errorWithDomain:NBErrorDomain
            code:NBClientErrorCodeService
            userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid response data.", nil),
                        NSLocalizedFailureReasonErrorKey: [NSString localizedStringWithFormat:
                                                           NSLocalizedString(@"No results found at '%@'.", nil),
                                                           resultsKey],
                        NSLocalizedRecoverySuggestionErrorKey: self.defaultErrorRecoverySuggestion }];
}

- (void)logResponse:(NSHTTPURLResponse *)response
               data:(NSData *)data
{
    NSLog(@"RESPONSE: %@\n"
          @"BODY: %@",
          response,
          [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

@end
