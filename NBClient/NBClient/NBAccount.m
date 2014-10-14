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
#import "NBClient+People.h"

@interface NBAccount ()

@property (nonatomic, strong, readwrite) NBClient *client;
@property (nonatomic, strong, readwrite) NSDictionary *defaultClientInfo;

@property (nonatomic, strong) NBAuthenticator *authenticator;
@property (nonatomic, strong) NSDictionary *clientInfo;

@property (nonatomic, strong) NSDictionary *person;

- (NSURL *)baseURL;

- (void)fetchPersonWithCompletionHandler:(NBGenericCompletionHandler)completionHandler;
- (void)fetchAvatarWithCompletionHandler:(NBGenericCompletionHandler)completionHandler;

@end

@implementation NBAccount

@synthesize name = _name;
@synthesize avatarImageData = _avatarImageData;

- (instancetype)initWithClientInfo:(NSDictionary *)clientInfoOrNil;
{
    self = [super init];
    if (self) {
        // Set defaults.
        self.shouldUseTestToken = NO;
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
        // Fill in redirect path if needed.
        mutableClientInfo[NBInfoRedirectPathKey] = mutableClientInfo[NBInfoRedirectPathKey] ?: NBAuthenticationDefaultRedirectPath;
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
    if (self.shouldUseTestToken) {
        self.client = [[NBClient alloc] initWithNationName:self.clientInfo[NBInfoNationNameKey]
                                                    apiKey:self.clientInfo[NBInfoTestTokenKey]
                                             customBaseURL:[self baseURL]
                                          customURLSession:nil customURLSessionConfiguration:nil];
    } else {
        self.client = [[NBClient alloc] initWithNationName:self.clientInfo[NBInfoNationNameKey]
                                             authenticator:self.authenticator
                                          customURLSession:nil customURLSessionConfiguration:nil];
    }
    return _client;
}

- (NBAuthenticator *)authenticator
{
    if (_authenticator) {
        return _authenticator;
    }
    self.authenticator = [[NBAuthenticator alloc] initWithBaseURL:[self baseURL]
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

- (void)setShouldUseTestToken:(BOOL)shouldUseTestToken
{
    if (shouldUseTestToken == _shouldUseTestToken) { return; }
    NSAssert(self.clientInfo[NBInfoTestTokenKey], @"Invalid client info: test token required.");
    // Boilerplate.
    static NSString *key;
    key = key ?: NSStringFromSelector(@selector(shouldUseTestToken));
    [self willChangeValueForKey:key];
    _shouldUseTestToken = shouldUseTestToken;
    [self didChangeValueForKey:key];
    // END: Boilerplate.
    self.client = nil;
}

- (NSURL *)baseURL
{
    return [NSURL URLWithString:
            [NSString stringWithFormat:self.clientInfo[NBInfoBaseURLFormatKey], self.clientInfo[NBInfoNationNameKey]]];
}

#pragma mark Presentation Helpers

- (NSString *)name
{
    if (!self.person) { return nil; }
    NSString *name = self.person[@"username"];
    name = name ?: self.person[@"full_name"];
    return name;
}

#pragma mark - Active API

- (void)requestActiveWithCompletionHandler:(NBGenericCompletionHandler)completionHandler
{
    [self.authenticator
     authenticateWithRedirectPath:self.clientInfo[NBInfoRedirectPathKey]
     completionHandler:^(NBAuthenticationCredential *credential, NSError *error) {
         if (error) {
             NSLog(@"ERROR: %@", error);
         } else if (credential) {
             // Success.
             NSLog(@"INFO: Activating account for nation %@", self.clientInfo[NBInfoNationNameKey]);
             self.client.apiKey = credential.accessToken;
             self.active = YES;
             // TODO: This will be more robust with an NSOperationQueue.
             [self fetchPersonWithCompletionHandler:completionHandler];
             return;
         } else {
             NSLog(@"WARNING: Unhandled case.");
         }
         if (completionHandler) {
             completionHandler(error);
         }
     }];
}

#pragma mark - Private

- (void)fetchPersonWithCompletionHandler:(NBGenericCompletionHandler)completionHandler
{
    [self.client fetchPersonForClientUserWithCompletionHandler:^(NSDictionary *item, NSError *error) {
        if (error) {
            NSLog(@"ERROR: %@", error);
        } else if (item) {
            // Success.
            self.person = item;
            [self fetchAvatarWithCompletionHandler:completionHandler];
        } else {
            NSLog(@"WARNING: Unhandled case.");
        }
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

- (void)fetchAvatarWithCompletionHandler:(NBGenericCompletionHandler)completionHandler
{
    NSURL *avatarURL = [NSURL URLWithString:self.person[@"profile_image_url_ssl"]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.avatarImageData = [NSData dataWithContentsOfURL:avatarURL];
        if (!self.avatarImageData) {
            NSLog(@"WARNING: Invalid avatar URL %@", avatarURL.absoluteString);
        }
        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil);
            });
        }
    });
}

@end
