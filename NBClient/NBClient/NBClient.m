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

@interface NBClient ()

@property (nonatomic, strong, readwrite) NSString *nationName;
@property (nonatomic, strong, readwrite) NSURLSession *urlSession;
@property (nonatomic, strong, readwrite) NSURLSessionConfiguration *sessionConfiguration;

@property (nonatomic, strong, readwrite) NBAuthenticator *authenticator;

@property (nonatomic, strong) NSString *nationHost;
@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) NSURLComponents *baseURLComponents;

- (void)commonInitWithNationName:(NSString *)nationName
                customURLSession:(NSURLSession *)urlSession
   customURLSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration;

- (NSURLRequest *)baseFetchRequestWithURL:(NSURL *)url;
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
    if (!_sessionConfiguration) {
        _sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    }
    if (_sessionConfiguration.URLCache) {
        const NSUInteger mb = 1024 * 1024;
        NSString *desiredApplicationSubdirectoryPath = self.nationHost;
        _sessionConfiguration.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * mb
                                                                       diskCapacity:20 * mb
                                                                           diskPath:desiredApplicationSubdirectoryPath];
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

#pragma mark Requests

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

- (NSURLRequest *)baseFetchRequestWithURL:(NSURL *)url
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadRevalidatingCacheData
                                                       timeoutInterval:10.0f];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    return request;
}

@end
