//
//  NBClient_Internal.h
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import "NBClient.h"

@interface NBClient () <NSURLSessionDelegate>

@property (nonatomic, copy, readwrite, nonnull) NSString *nationSlug;
@property (nonatomic, readwrite, nonnull) NSURLSession *urlSession;
@property (nonatomic, readwrite, nonnull) NSURLSessionConfiguration *sessionConfiguration;

@property (nonatomic, readwrite, nullable) NBAuthenticator *authenticator;

@property (nonatomic, readwrite, nonnull) NSURL *baseURL;
@property (nonatomic, null_resettable) NSURLComponents *baseURLComponents;
@property (nonatomic, copy, nonnull) NSString *defaultErrorRecoverySuggestion;

- (void)commonInitWithNationSlug:(nonnull NSString *)nationSlug
                customURLSession:(nullable NSURLSession *)urlSession
   customURLSessionConfiguration:(nullable NSURLSessionConfiguration *)sessionConfiguration;

- (void)updateBaseURLComponents;
- (nonnull NSURLComponents *)urlComponentsForSubPath:(nonnull NSString *)path;

- (nonnull NSMutableURLRequest *)baseRequestWithURL:(nonnull NSURL *)url
                                         parameters:(nullable NSDictionary *)parameters
                                              error:(NSError * __nullable * __nullable)error;

- (nonnull NSURLSessionDataTask *)baseDataTaskWithURLComponents:(nonnull NSURLComponents *)components
                                                     httpMethod:(nonnull NSString *)method
                                                     parameters:(nullable NSDictionary *)parameters
                                                     resultsKey:(nullable NSString *)resultsKey
                                                 paginationInfo:(nullable NBPaginationInfo *)paginationInfo
                                              completionHandler:(nullable id)completionHandler;

- (nonnull void (^)(NSData * __nonnull, NSURLResponse * __nonnull, NSError * __nullable))
  dataTaskCompletionHandlerForResultsKey:(nullable NSString *)resultsKey
                         originalRequest:(nonnull NSURLRequest *)request
                       completionHandler:(nullable void (^)(id __nullable results, NSDictionary * __nullable jsonObject, NSError * __nullable error))completionHandler;

- (nonnull NSError *)errorForResponse:(nonnull NSHTTPURLResponse *)response jsonData:(nonnull NSDictionary *)data;
- (nonnull NSError *)errorForJsonData:(nonnull NSDictionary *)data resultsKey:(nonnull NSString *)resultsKey;
- (void)logResponse:(nullable NSHTTPURLResponse *)response data:(nullable id)data;

@end
