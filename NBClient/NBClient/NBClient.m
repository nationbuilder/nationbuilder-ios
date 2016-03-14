//
//  NBClient.m
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBClient.h"
#import "NBClient_Internal.h"

#import "NBAuthenticator.h"
#import "FoundationAdditions.h"
#import "NBPaginationInfo.h"

# pragma mark - External Constants

NSUInteger const NBClientErrorCodeService = 10;
NSString * const NBClientErrorCodeKey = @"code";
NSString * const NBClientErrorHTTPStatusCodeKey = @"NBClientErrorHTTPStatusCode";
NSString * const NBClientErrorMessageKey = @"message";
NSString * const NBClientErrorValidationErrorsKey = @"validation_errors";
NSString * const NBClientErrorInnerErrorKey = @"inner_error";

NSString * const NBClientDefaultAPIVersion = @"v1";
NSString * const NBClientDefaultBaseURLFormat = @"https://%@.nationbuilder.com";

NSString * const NBClientPaginationTokenOptInKey = @"token_paginator";

NSString * const NBClientLocationLatitudeKey = @"latitude";
NSString * const NBClientLocationLongitudeKey = @"longitude";
NSString * const NBClientLocationProximityDistanceKey = @"distance";

NSString * const NBClientTaggingTagNameOrListKey = @"tag";

NSString * const NBClientCapitalAmountInCentsKey = @"amount_in_cents";
NSString * const NBClientCapitalUserContentKey = @"content";

NSString * const NBClientNoteUserContentKey = @"content";

NSString * const NBClientContactBroadcasterIdentifierKey = @"broadcaster_id";
NSString * const NBClientContactMethodKey = @"method";
NSString * const NBClientContactNoteKey = @"note";
NSString * const NBClientContactSenderIdentifierKey = @"sender_id";
NSString * const NBClientContactStatusKey = @"status";
NSString * const NBClientContactTypeIdentifierKey = @"type_id";

NSString * const NBClientDonationAmountInCentsKey = @"amount_in_cents";
NSString * const NBClientDonationDonorIdentifierKey = @"donor_id";
NSString * const NBClientDonationPaymentTypeNameKey = @"payment_type_name";

NSString * const NBClientSurveyResponderIdentifierKey = @"person_id";
NSString * const NBClientSurveyResponsesKey = @"question_responses";
NSString * const NBClientSurveyQuestionIdentifierKey = @"question_id";
NSString * const NBClientSurveyQuestionResponseIdentifierKey = @"response";

#pragma mark - Internal Constants

#if DEBUG
static NBLogLevel LogLevel = NBLogLevelDebug;
#else
static NBLogLevel LogLevel = NBLogLevelWarning;
#endif

#pragma mark -

@implementation NBClient

#pragma mark - Initializers

- (instancetype)initWithNationSlug:(NSString *)nationSlug
                     authenticator:(NBAuthenticator *)authenticator
                  customURLSession:(NSURLSession *)urlSession
     customURLSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration
{
    self = [super init];
    if (self) {
        [self commonInitWithNationSlug:nationSlug customURLSession:urlSession customURLSessionConfiguration:sessionConfiguration];
        self.authenticator = authenticator;
    }
    return self;
}

- (instancetype)initWithNationSlug:(NSString *)nationSlug
                            apiKey:(NSString *)apiKey
                     customBaseURL:(NSURL *)baseURL
                  customURLSession:(NSURLSession *)urlSession
     customURLSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration
{
    self = [super init];
    if (self) {
        [self commonInitWithNationSlug:nationSlug customURLSession:urlSession customURLSessionConfiguration:sessionConfiguration];
        self.apiKey = apiKey;
        self.baseURL = baseURL;
    }
    return self;
}

- (void)commonInitWithNationSlug:(NSString *)nationSlug
                customURLSession:(NSURLSession *)urlSession
   customURLSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration
{
    self.nationSlug = nationSlug;
    self.urlSession = urlSession;
    self.sessionConfiguration = sessionConfiguration;
    
    self.defaultErrorRecoverySuggestion = @"message.unknown-error-solution".nb_localizedString;
    
    self.baseURL = [NSURL URLWithString:[NSString stringWithFormat:NBClientDefaultBaseURLFormat, self.nationSlug]];
    self.shouldUseLegacyPagination = NO;
    self.shouldUseTokenPagination = YES;
}

#pragma mark - NBLogging

+ (void)updateLoggingToLevel:(NBLogLevel)logLevel
{
    LogLevel = logLevel;
}

#pragma mark - Accessors

@synthesize urlSession = _urlSession;
@synthesize sessionConfiguration = _sessionConfiguration;
@synthesize authenticator = _authenticator;
@synthesize apiKey = _apiKey;
@synthesize apiVersion = _apiVersion;

- (void)setBaseURL:(NSURL *)baseURL
{
    _baseURL = baseURL;
    [self updateBaseURLComponents];
}

- (NSURLSession *)urlSession
{
    if (_urlSession) {
        return _urlSession;
    }
    id <NSURLSessionDelegate> delegate = self.delegate ? (id)self.delegate : self;
    self.urlSession = [NSURLSession sessionWithConfiguration:self.sessionConfiguration
                                                    delegate:delegate
                                               delegateQueue:[NSOperationQueue mainQueue]];
    return _urlSession;
}

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

- (void)setAuthenticator:(NBAuthenticator *)authenticator
{
    _authenticator = authenticator;
    // Did.
    if (authenticator && authenticator.baseURL) {
        self.baseURL = authenticator.baseURL;
    }
}

- (void)setApiKey:(NSString *)apiKey
{
    _apiKey = apiKey;
    [self updateBaseURLComponents];
}

- (NSString *)apiVersion
{
    if (_apiVersion) {
        return _apiVersion;
    }
    self.apiVersion = NBClientDefaultAPIVersion;
    return _apiVersion;
}
- (void)setApiVersion:(NSString *)apiVersion
{
    if (!apiVersion) {
        return;
    }
    _apiVersion = apiVersion;
    [self updateBaseURLComponents];
}

#pragma mark - Generic Endpoints

- (NSURLSessionDataTask *)fetchByResourceSubPath:(NSString *)path
                                  withParameters:(NSDictionary *)parameters
                                customResultsKey:(NSString *)resultsKey
                                  paginationInfo:(NBPaginationInfo *)paginationInfo
                               completionHandler:(id)completionHandler
{
    resultsKey = resultsKey ?: @"results";
    return [self baseDataTaskWithURLComponents:[self urlComponentsForSubPath:path]
                                    httpMethod:@"GET" parameters:parameters resultsKey:resultsKey
                                paginationInfo:paginationInfo completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)createByResourceSubPath:(NSString *)path
                                   withParameters:(NSDictionary *)parameters
                                       resultsKey:(NSString *)resultsKey
                                completionHandler:(id)completionHandler
{
    return [self baseDataTaskWithURLComponents:[self urlComponentsForSubPath:path]
                                    httpMethod:@"POST" parameters:parameters resultsKey:resultsKey
                                paginationInfo:nil completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)saveByResourceSubPath:(NSString *)path
                                 withParameters:(NSDictionary *)parameters
                                     resultsKey:(NSString *)resultsKey
                              completionHandler:(id)completionHandler
{
    return [self baseDataTaskWithURLComponents:[self urlComponentsForSubPath:path]
                                    httpMethod:@"PUT" parameters:parameters resultsKey:resultsKey
                                paginationInfo:nil completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)deleteByResourceSubPath:(NSString *)path
                                   withParameters:(NSDictionary *)parameters
                                       resultsKey:(NSString *)resultsKey
                                completionHandler:(id)completionHandler
{
    return [self baseDataTaskWithURLComponents:[self urlComponentsForSubPath:path]
                                    httpMethod:@"DELETE" parameters:parameters resultsKey:resultsKey
                                paginationInfo:nil completionHandler:completionHandler];
}

#pragma mark - Internal

#pragma mark Requests & Tasks

@synthesize baseURLComponents = _baseURLComponents;

- (NSURLComponents *)baseURLComponents
{
    if (_baseURLComponents) {
        return _baseURLComponents;
    }
    [self updateBaseURLComponents];
    return _baseURLComponents;
}

- (void)updateBaseURLComponents
{
    self.baseURLComponents = [NSURLComponents componentsWithURL:self.baseURL resolvingAgainstBaseURL:YES];
    self.baseURLComponents.path = [NSString stringWithFormat:@"/api/%@", self.apiVersion];
    self.baseURLComponents.percentEncodedQuery = @{ @"access_token": self.apiKey ?: @"" }.nb_queryString;
}

- (NSURLComponents *)urlComponentsForSubPath:(NSString *)path
{
    NSURLComponents *components = self.baseURLComponents.copy;
    components.path = [components.path stringByAppendingString:path];
    return components;
}

- (NSMutableURLRequest *)baseRequestWithURL:(NSURL *)url
                                 parameters:(NSDictionary *)parameters
                                      error:(NSError *__autoreleasing *)error
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0f];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    if (parameters) {
        [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:parameters options:0 error:error]];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(client:willCreateDataTaskForRequest:)]) {
        [self.delegate client:self willCreateDataTaskForRequest:request];
    }
    return request;
}

- (NSURLSessionDataTask *)baseDataTaskWithURLComponents:(NSURLComponents *)components
                                             httpMethod:(NSString *)method
                                             parameters:(NSDictionary *)parameters
                                             resultsKey:(NSString *)resultsKey
                                         paginationInfo:(NBPaginationInfo *)paginationInfo
                                      completionHandler:(id)completionHandler
{
    // Step 1: Finalize URL components.
    NSMutableDictionary *mutableParameters;
    if (paginationInfo) {
        // Add pagination query parameters.
        paginationInfo.legacy = self.shouldUseLegacyPagination;
        mutableParameters = paginationInfo.queryParameters.mutableCopy;
        if (!paginationInfo.legacy && self.shouldUseTokenPagination) {
            // Only add the flag if opting in, necessary for older apps.
            mutableParameters[NBClientPaginationTokenOptInKey] = @1;
        }
        [mutableParameters addEntriesFromDictionary:components.percentEncodedQuery.nb_queryStringParameters];
    }
    if (parameters && [method isEqualToString:@"GET"]) {
        // Add custom query parameters.
        if (!mutableParameters) {
            mutableParameters = components.percentEncodedQuery.nb_queryStringParameters.mutableCopy;
        }
        [mutableParameters addEntriesFromDictionary:parameters];
        parameters = nil;
    }
    if (mutableParameters) {
        components.percentEncodedQuery = mutableParameters.nb_queryString;
    }

    // Step 2: Create request.
    NSError *jsonError;
    NSMutableURLRequest *request = [self baseRequestWithURL:components.URL parameters:parameters error:&jsonError];
    if (jsonError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Requires interface deprecation to enable.
            // if (!resultsKey) {
            //    ((NBClientEmptyCompletionHandler)completionHandler)(jsonError);
            // }
            if (paginationInfo || [resultsKey isEqualToString:@"results"]
                || [resultsKey hasSuffix:@"s"]) // This additional check is due to API naming inconsistency.
            {
                ((NBClientResourceListCompletionHandler)completionHandler)(nil, nil, jsonError);
            } else {
                ((NBClientResourceCompletionHandler)completionHandler)(nil, jsonError);
            }
        });
        return nil;
    }
    request.HTTPMethod = method;
    if ([request.HTTPMethod isEqualToString:@"GET"]) {
        request.cachePolicy = NSURLRequestReloadRevalidatingCacheData;
    }
    NBLogInfo(@"REQUEST: %@", request.nb_debugDescription);

    // Step 3: Create task with handler.
    void (^taskCompletionHandler)(NSData *, NSURLResponse *, NSError *) =
    [self dataTaskCompletionHandlerForResultsKey:resultsKey originalRequest:request completionHandler:^(id results, NSDictionary *jsonObject, NSError *error) {
        if (completionHandler) {
            if ([results isKindOfClass:[NSArray class]] || paginationInfo) {
                NBPaginationInfo *responsePaginationInfo;
                if ([NBPaginationInfo dictionaryContainsPaginationInfo:jsonObject]) {
                    responsePaginationInfo = [[NBPaginationInfo alloc] initWithDictionary:jsonObject legacy:paginationInfo.legacy];
                    responsePaginationInfo.numberOfItemsPerPage = paginationInfo.numberOfItemsPerPage;
                    responsePaginationInfo.currentDirection = paginationInfo.currentDirection;
                    [responsePaginationInfo updateCurrentPageNumber];
                }
                ((NBClientResourceListCompletionHandler)completionHandler)(results, responsePaginationInfo, error);
            } else if ([results isKindOfClass:[NSDictionary class]]) {
                ((NBClientResourceItemCompletionHandler)completionHandler)(results, error);
            } else if (results) {
                ((NBClientResourceCompletionHandler)completionHandler)(results, error);
            } else if (!results) {
                ((NBClientResourceItemCompletionHandler)completionHandler)(results, error);
                // Requires interface deprecation to replace above.
                // ((NBClientEmptyCompletionHandler)completionHandler)(results);
            } else {
                NBLogError(@"Client cannot infer block type, completion not called! %@", completionHandler);
            }
        }
    }];
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request completionHandler:taskCompletionHandler];

    // Step 4: Optionally start task.
    BOOL shouldStart = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(client:shouldAutomaticallyStartDataTask:)]) {
        shouldStart = [self.delegate client:self shouldAutomaticallyStartDataTask:task];
    }
    if (shouldStart) {
        [task resume];
    }
    return task;
}

#pragma mark Handlers

- (void (^)(NSData *, NSURLResponse *, NSError *))dataTaskCompletionHandlerForResultsKey:(NSString *)resultsKey
                                                                         originalRequest:(NSURLRequest *)request
                                                                       completionHandler:(void (^)(id, NSDictionary *, NSError *))completionHandler
{
    return ^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        // Bail if delegate wants to handle the whole thing.
        if (self.delegate && [self.delegate respondsToSelector:@selector(client:shouldHandleResponse:forRequest:)]) {
            if (![self.delegate client:self shouldHandleResponse:httpResponse forRequest:request]) {
                return [self logResponse:httpResponse data:data]; // Combined to a one-liner; returns void.
            }
        }
        // Handle data task error.
        if (error) {
            NBLogError(@"%@", error);
            if (self.delegate && [self.delegate respondsToSelector:@selector(client:shouldHandleResponse:forRequest:withDataTaskError:)]) {
                if (![self.delegate client:self shouldHandleResponse:httpResponse forRequest:request withDataTaskError:error]) {
                    return [self logResponse:httpResponse data:data];
                }
            }
            if (completionHandler) { completionHandler(nil, nil, error); }
            return [self logResponse:httpResponse data:data];
        }
        // Handle empty bodies.
        if ([[NSIndexSet nb_indexSetOfSuccessfulEmptyResponseHTTPStatusCodes] containsIndex:(NSUInteger)httpResponse.statusCode]) {
            if (completionHandler) { completionHandler(nil, nil, error); }
            return [self logResponse:httpResponse data:data];
        }
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingAllowFragments
                                                                     error:&error];
        // Handle HTTP error.
        if (![[NSIndexSet nb_indexSetOfSuccessfulHTTPStatusCodes] containsIndex:(NSUInteger)httpResponse.statusCode]) {
            error = [self errorForResponse:httpResponse jsonData:jsonObject];
            if (self.delegate && [self.delegate respondsToSelector:@selector(client:shouldHandleResponse:forRequest:withHTTPError:)]) {
                if (![self.delegate client:self shouldHandleResponse:httpResponse forRequest:request withHTTPError:error]) {
                    return [self logResponse:httpResponse data:data];
                }
            }
            NBLogError(@"%@", error);
            if (completionHandler) { completionHandler(nil, nil, error); }
            return [self logResponse:httpResponse data:data];
        }
        // Handle JSON error.
        if (error) {
            NBLogError(@"%@", error);
            if (completionHandler) { completionHandler(nil, nil, error); }
            return [self logResponse:httpResponse data:data];
        }
        // Handle Non-HTTP error or invalid response.
        if (jsonObject[@"code"]) {
            error = [self errorForResponse:httpResponse jsonData:jsonObject];
            if (self.delegate && [self.delegate respondsToSelector:@selector(client:shouldHandleResponse:forRequest:withServiceError:)]) {
                if (![self.delegate client:self shouldHandleResponse:httpResponse forRequest:request withServiceError:error]) {
                    return [self logResponse:httpResponse data:data];
                }
            }
        }
        // Get and check for results.
        if (self.delegate && [self.delegate respondsToSelector:@selector(client:didParseJSON:fromResponse:forRequest:)]) {
            [self.delegate client:self didParseJSON:jsonObject fromResponse:httpResponse forRequest:request];
        }
        id results;
        if (resultsKey) {
            results = jsonObject[resultsKey];
            if (!results) {
                error = [self errorForJsonData:jsonObject resultsKey:resultsKey];
            }
        }
        if (error) {
            NBLogError(@"%@", error);
        }
        // Completed. Successful if error is nil.
        [self logResponse:httpResponse data:jsonObject];
        if (completionHandler) {
            completionHandler(results, jsonObject, error);
        }
    };
}

#pragma mark Helpers

- (NSError *)errorForResponse:(NSHTTPURLResponse *)response
                     jsonData:(NSDictionary *)data
{
    NSString *code = data[@"code"] ? data[@"code"] : @"unknown";
    NSString *description;
    if ([[NSIndexSet nb_indexSetOfSuccessfulHTTPStatusCodes] containsIndex:(NSUInteger)response.statusCode]) {
        description = [NSString localizedStringWithFormat:@"message.nb-error.format".nb_localizedString, code];
    } else {
        description = [NSString localizedStringWithFormat:@"message.nb-http-error.format".nb_localizedString,
                       response.statusCode, code];
    }
    return [NSError
            errorWithDomain:NBErrorDomain
            code:NBClientErrorCodeService
            userInfo:@{ NSLocalizedDescriptionKey: description,
                        NSLocalizedFailureReasonErrorKey: (data[@"message"] ? data[@"message"] : @"message.unknown-error-reason".nb_localizedString),
                        NSLocalizedRecoverySuggestionErrorKey: self.defaultErrorRecoverySuggestion,
                        NBClientErrorCodeKey: (data[NBClientErrorCodeKey] ? data[NBClientErrorCodeKey] : @""),
                        NBClientErrorHTTPStatusCodeKey: @(response.statusCode),
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
            userInfo:@{ NSLocalizedDescriptionKey: @"message.invalid-response-data".nb_localizedString,
                        NSLocalizedFailureReasonErrorKey: [NSString localizedStringWithFormat:
                                                           @"message.no-json-results-for-key.format".nb_localizedString,
                                                           resultsKey],
                        NSLocalizedRecoverySuggestionErrorKey: self.defaultErrorRecoverySuggestion }];
}

- (void)logResponse:(NSHTTPURLResponse *)response
               data:(id)data
{
    id body = ([data isKindOfClass:[NSData class]]
               ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
               : data);
    NBLogInfo(@"RESPONSE: %@\n"
              @"BODY: %@",
              response, body);
}

@end
