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
- (NSURLSessionDataTask *)baseFetchTaskWithURL:(NSURL *)url
                                    resultsKey:(NSString *)resultsKey
                             completionHandler:(void (^)(id results, NSError *error))completionHandler;

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

- (NSURLSessionDataTask *)fetchPeopleWithCompletionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    NSURLComponents *components = self.baseURLComponents.copy;
    components.path = [components.path stringByAppendingString:@"/people"];
    return [self baseFetchTaskWithURL:components.URL resultsKey:@"results" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchPeopleByParameters:(NSDictionary *)parameters
                            withCompletionHandler:(NBClientResourceListCompletionHandler)completionHandler
{
    NSURLComponents *components = self.baseURLComponents.copy;
    components.path = [components.path stringByAppendingString:@"/people/search"];
    components.query = [components.query stringByAppendingFormat:@"&%@",
                        [parameters nb_queryStringWithEncoding:NSASCIIStringEncoding
                                   skipPercentEncodingPairKeys:nil charactersToLeaveUnescaped:nil]];
    return [self baseFetchTaskWithURL:components.URL resultsKey:@"results" completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)fetchPersonByIdentifier:(NSUInteger)identifier
                            withCompletionHandler:(NBClientResourceItemCompletionHandler)completionHandler
{
    NSURLComponents *components = self.baseURLComponents.copy;
    components.path = [components.path stringByAppendingString:
                       [NSString stringWithFormat:@"/people/%d", identifier]];
    return [self baseFetchTaskWithURL:components.URL resultsKey:@"person" completionHandler:completionHandler];
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
    return [self baseFetchTaskWithURL:components.URL resultsKey:@"person" completionHandler:completionHandler];
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

- (NSURLSessionDataTask *)baseFetchTaskWithURL:(NSURL *)url
                                    resultsKey:(NSString *)resultsKey
                             completionHandler:(void (^)(id, NSError *))completionHandler
{
    NSURLSessionDataTask *task =
    [self.urlSession
     dataTaskWithRequest:[self baseFetchRequestWithURL:url]
     completionHandler:[self dataTaskCompletionHandlerForFetchResultsKey:resultsKey completionHandler:^(id results, NSError *error) {
        if (completionHandler) {
            completionHandler(results, error);
        }
    }]];
    [task resume];
    return task;
}

#pragma mark Handlers

- (void (^)(NSData *, NSURLResponse *, NSError *))dataTaskCompletionHandlerForFetchResultsKey:(NSString *)resultsKey
                                                                            completionHandler:(void (^)(id results, NSError *error))completionHandler
{
    return ^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (data) {
            [self logResponse:httpResponse data:data];
        }
        // Handle data task error.
        if (error) {
            if (completionHandler) {
                completionHandler(nil, error);
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
                completionHandler(nil, error);
            }
            return;
        }
        // Handle JSON error.
        if (error) {
            if (completionHandler) {
                completionHandler(nil, error);
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
            completionHandler(results, error);
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
