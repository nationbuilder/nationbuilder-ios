//
//  NBAccount.m
//  NBClient
//
//  Created by Peng Wang on 10/9/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBAccount.h"

#import "NBAuthenticator.h"
#import "NBClient.h"
#import "NBDefines.h"

@interface NBAccount ()

@property (nonatomic, strong, readwrite) NBClient *client;
@property (nonatomic, strong, readwrite) NSDictionary *defaultClientInfo;

@property (nonatomic, strong) NBAuthenticator *authenticator;
@property (nonatomic, strong) NSDictionary *clientInfo;

@end

@implementation NBAccount

- (instancetype)initWithClientInfo:(NSDictionary *)clientInfoOrNil;
{
    self = [super init];
    if (self) {
        if (!clientInfoOrNil) {
            clientInfoOrNil = self.defaultClientInfo;
        }
        NSMutableDictionary *mutableClientInfo = clientInfoOrNil.mutableCopy;
        // Fill in OAuth client ID if needed.
        mutableClientInfo[NBInfoClientIdentifierKey] = mutableClientInfo[NBInfoClientIdentifierKey] ?: self.defaultClientInfo[NBInfoClientIdentifierKey];
        // Check for developer.
        NSAssert(mutableClientInfo[NBInfoNationNameKey] && mutableClientInfo[NBInfoClientIdentifierKey],
                 @"Invalid client info: nation slug and OAuth client ID required.");
        // Fill in client base URL if needed.
        mutableClientInfo[NBInfoBaseURLFormatKey] = mutableClientInfo[NBInfoBaseURLFormatKey] ?: self.defaultClientInfo[NBInfoBaseURLFormatKey];
        mutableClientInfo[NBInfoBaseURLFormatKey] = mutableClientInfo[NBInfoBaseURLFormatKey] ?: NBClientDefaultBaseURLFormat;
        // Set.
        self.clientInfo = [NSDictionary dictionaryWithDictionary:mutableClientInfo];
    }
    return self;
}

#pragma mark - Accessors

- (NBClient *)client
{
    if (_client) {
        return _client;
    }
    self.client = [[NBClient alloc] initWithNationName:self.clientInfo[NBInfoNationNameKey]
                                         authenticator:self.authenticator
                                      customURLSession:nil customURLSessionConfiguration:nil];
    return _client;
}

- (NBAuthenticator *)authenticator
{
    if (_authenticator) {
        return _authenticator;
    }
    NSString *baseURLString = [NSString stringWithFormat:self.clientInfo[NBInfoBaseURLFormatKey], self.clientInfo[NBInfoNationNameKey]];
    self.authenticator = [[NBAuthenticator alloc] initWithBaseURL:[NSURL URLWithString:baseURLString]
                                                 clientIdentifier:self.clientInfo[NBInfoClientIdentifierKey]];
    return _authenticator;
}

- (NSDictionary *)defaultClientInfo
{
    if (_defaultClientInfo) {
        return _defaultClientInfo;
    }
    NSString *path = [[NSBundle mainBundle] pathForResource:NBInfoFileName ofType:@"plist"];
    NSAssert(path, @"%@.plist could not be found. Either supply a proper info dictionary to "
                   @"the constructor or ensure the proper plist exists.", NBInfoFileName);
    self.defaultClientInfo = [NSDictionary dictionaryWithContentsOfFile:path];
    return _defaultClientInfo;
}

- (void)setActive:(BOOL)active
{
    // Boilerplate.
    // TODO: Make into snippet.
    static NSString *key;
    key = key ?: NSStringFromSelector(@selector(isActive));
    [self willChangeValueForKey:key];
    _active = active;
    [self didChangeValueForKey:key];
    // END: Boilerplate.
    // TODO: Not ideal.
    [self.authenticator authenticateWithCompletionHandler:^(NBAuthenticationCredential *credential, NSError *error) {
        _active = !!error;
    }];
}

@end
