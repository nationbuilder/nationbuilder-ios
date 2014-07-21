//
//  NBClient.m
//  NBClient
//
//  Created by Peng Wang on 7/8/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBClient.h"

#import "NBAuthenticator.h"
#import "NBDefines.h"
#import "NBFoundationAdditions.h"
#import "NBPaginationInfo.h"

NSUInteger const NBClientErrorCodeService = 1;

@interface NBClient ()

@property (nonatomic, strong, readwrite) NSString *nationName;
@property (nonatomic, strong, readwrite) NSURLSession *urlSession;
@property (nonatomic, strong, readwrite) NSURLSessionConfiguration *sessionConfiguration;

@property (nonatomic, strong, readwrite) NBAuthenticator *authenticator;

@property (nonatomic, strong) NSString *nationHost;
@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) NSURLComponents *baseURLComponents;
@property (nonatomic, strong) NSString *defaultErrorRecoverySuggestion;

- (void)commonInitWithNationName:(NSString *)nationName
                customURLSession:(NSURLSession *)urlSession
   customURLSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration;

- (NSMutableURLRequest *)baseFetchRequestWithURL:(NSURL *)url;
- (NSURLSessionDataTask *)baseFetchTaskWithURLComponents:(NSURLComponents *)components
                                              resultsKey:(NSString *)resultsKey
                                          paginationInfo:(NBPaginationInfo **)paginationInfo
                                       completionHandler:(void (^)(id, NSError *))completionHandler;

- (NSMutableURLRequest *)baseSaveRequestWithURL:(NSURL *)url
                                     parameters:(NSDictionary *)parameters
                                          error:(NSError **)error;
- (NSURLSessionDataTask *)baseSaveTaskWithURLRequest:(NSURLRequest *)request
                                          resultsKey:(NSString *)resultsKey
                                   completionHandler:(void (^)(id results, NSError *error))completionHandler;

- (NSMutableURLRequest *)baseDeleteRequestWithURL:(NSURL *)url;
- (NSURLSessionDataTask *)baseDeleteTaskWithURL:(NSURL *)url
                              completionHandler:(void (^)(id results, NSError *error))completionHandler;

- (void (^)(NSData *, NSURLResponse *, NSError *))dataTaskCompletionHandlerForFetchResultsKey:(NSString *)resultsKey
                                                                            completionHandler:(void (^)(id results, NSDictionary *jsonObject, NSError *error))completionHandler;

- (NSError *)httpErrorForResponse:(NSHTTPURLResponse *)response jsonData:(NSDictionary *)data;
- (NSError *)invalidErrorForJsonData:(NSDictionary *)data resultsKey:(NSString *)resultsKey;
- (NSError *)nonHTTPErrorForResponse:(NSHTTPURLResponse *)response jsonData:(NSDictionary *)data;
- (void)logResponse:(NSHTTPURLResponse *)response data:(NSData *)data;

@end

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
                  customURLSession:(NSURLSession *)urlSession
     customURLSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration
{
    self = [super init];
    if (self) {
        [self commonInitWithNationName:nationName customURLSession:urlSession customURLSessionConfiguration:sessionConfiguration];
        self.apiKey = apiKey;
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

#pragma mark - Public

#pragma mark People

- (NSURLSessionDataTask *)fetchPeopleWithPaginationInfo:(NBPaginationInfo *__autoreleasing *)paginationInfo
                                      completionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    NSURLComponents *components = self.baseURLComponents.copy;
    components.path = [components.path stringByAppendingString:@"/people"];
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"results" paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchPeopleByParameters:(NSDictionary *)parameters
                               withPaginationInfo:(NBPaginationInfo *__autoreleasing *)paginationInfo
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
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"person" paginationInfo:nil completionHandler:completionHandler];
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
    return [self baseFetchTaskWithURLComponents:components resultsKey:@"person" paginationInfo:nil completionHandler:completionHandler];
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

#pragma mark - Private

#pragma mark Accessors

- (void)setNationName:(NSString *)nationName
{
    if ([_nationName isEqual:nationName]) {
        return;
    }
    _nationName = nationName;
    self.nationHost = nil;
    self.baseURL = nil;
    self.baseURLComponents = nil;
}

- (NSURLSessionConfiguration *)sessionConfiguration
{
    static NSURLCache *sharedCache;
    BOOL shouldUseDefaultCache = !_sessionConfiguration || !_sessionConfiguration.URLCache;
    if (shouldUseDefaultCache) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            const NSUInteger mb = 1024 * 1024;
            NSString *desiredApplicationSubdirectoryPath = self.nationHost;
            sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * mb
                                                        diskCapacity:20 * mb
                                                            diskPath:desiredApplicationSubdirectoryPath];
        });
    }
    if (!_sessionConfiguration) {
        _sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
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
    _urlSession = [NSURLSession sessionWithConfiguration:self.sessionConfiguration
                                                delegate:self
                                           delegateQueue:[NSOperationQueue mainQueue]];
    return _urlSession;
}

- (NSString *)nationHost
{
    if (_nationHost) {
        return _nationHost;
    }
    _nationHost = [NSString stringWithFormat:@"%@.nationbuilder.com", self.nationName];
    return _nationHost;
}

#pragma mark Requests & Tasks

- (NSURL *)baseURL
{
    if (_baseURL) {
        return _baseURL;
    }
    NSString *format = [[NSUserDefaults standardUserDefaults] stringForKey:@"NBBaseURLFormat"];
    if (!format) {
        format = @"https://%@.nationbuilder.com";
    }
    _baseURL = [NSURL URLWithString:[NSString stringWithFormat:format, self.nationName]];
    return _baseURL;
}

- (NSURLComponents *)baseURLComponents
{
    if (_baseURLComponents) {
        return _baseURLComponents;
    }
    _baseURLComponents = [NSURLComponents componentsWithURL:self.baseURL resolvingAgainstBaseURL:YES];
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
    [task resume];
    return task;
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
    [task resume];
    return task;
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
            error = [self httpErrorForResponse:httpResponse jsonData:jsonObject];
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
            error = [self nonHTTPErrorForResponse:httpResponse jsonData:jsonObject];
        }
        id results = jsonObject[resultsKey];
        // Handle invalid response.
        if (!results) {
            error = [self invalidErrorForJsonData:jsonObject resultsKey:resultsKey];
        }
        if (completionHandler) {
            completionHandler(results, jsonObject, error);
        }
    };
}

#pragma mark Helpers

- (NSError *)httpErrorForResponse:(NSHTTPURLResponse *)response jsonData:(NSDictionary *)data
{
    return [NSError
            errorWithDomain:NBErrorDomain
            code:NBClientErrorCodeService
            userInfo:@{ NSLocalizedDescriptionKey: [NSString localizedStringWithFormat:
                                                    NSLocalizedString(@"Service errored fulfilling request, status code: %d (%@)", nil),
                                                    response.statusCode, data[@"code"]],
                        NSLocalizedFailureReasonErrorKey: NSLocalizedString(data[@"message"] ? data[@"message"] : @"Reason unknown.", nil),
                        NSLocalizedRecoverySuggestionErrorKey: self.defaultErrorRecoverySuggestion }];
}

- (NSError *)invalidErrorForJsonData:(NSDictionary *)data resultsKey:(NSString *)resultsKey
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

- (NSError *)nonHTTPErrorForResponse:(NSHTTPURLResponse *)response jsonData:(NSDictionary *)data
{
    return [NSError
            errorWithDomain:NBErrorDomain
            code:NBClientErrorCodeService
            userInfo:@{ NSLocalizedDescriptionKey: [NSString localizedStringWithFormat:
                                                    NSLocalizedString(@"Service errored fulfilling request, status code: %d (%@)", nil),
                                                    response.statusCode, data[@"code"]],
                        NSLocalizedFailureReasonErrorKey: NSLocalizedString(data[@"message"] ? data[@"message"] : @"Reason unknown.", nil),
                        NSLocalizedRecoverySuggestionErrorKey: self.defaultErrorRecoverySuggestion }];
}

- (void)logResponse:(NSHTTPURLResponse *)response data:(NSData *)data
{
    NSLog(@"RESPONSE: %@\n"
          @"BODY: %@",
          response,
          [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

@end
