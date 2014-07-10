//
//  NBClient.m
//  NBClient
//
//  Created by Peng Wang on 7/8/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBClient.h"

@interface NBClient ()

@property (nonatomic, strong, readwrite) NSString *nationName;
@property (nonatomic, strong, readwrite) NSString *apiKey;
@property (nonatomic, strong, readwrite) NSURLSession *urlSession;
@property (nonatomic, strong, readwrite) NSURLSessionConfiguration *sessionConfiguration;

@property (nonatomic, weak, readonly) NSString *nationHost;

@end

@implementation NBClient

- (instancetype)initWithNationName:(NSString *)nationName
                            apiKey:(NSString *)apiKey
                  customURLSession:(NSURLSession *)urlSession
     customURLSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration
{
    self = [super init];
    if (self) {
        self.nationName = nationName;
        self.apiKey = apiKey;
        self.urlSession = urlSession;
        self.sessionConfiguration = sessionConfiguration;
    }
    return self;
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
