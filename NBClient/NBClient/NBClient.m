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

@interface NBClient ()

@property (nonatomic, strong, readwrite) NSString *nationName;
@property (nonatomic, strong, readwrite) NSString *apiKey;
@property (nonatomic, strong, readwrite) NSURLSession *urlSession;
@property (nonatomic, strong, readwrite) NSURLSessionConfiguration *sessionConfiguration;

@property (nonatomic, strong, readwrite) NBAuthenticator *authenticator;

@property (nonatomic, weak, readonly) NSString *nationHost;

- (void)commonInitWithNationName:(NSString *)nationName
                customURLSession:(NSURLSession *)urlSession
   customURLSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration;

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

#pragma mark Computed Properties

- (NSString *)nationHost
{
    return [NSString stringWithFormat:@"%@.nationbuilder.com", self.nationName];
}

@end
