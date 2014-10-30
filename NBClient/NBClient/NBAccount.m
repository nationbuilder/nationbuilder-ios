//
//  NBAccount.m
//  NBClient
//
//  Created by Peng Wang on 10/9/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBAccount.h"

#import "FoundationAdditions.h"
#import "NBAuthenticator.h"
#import "NBClient.h"
#import "NBClient+People.h"

#if DEBUG
static NBLogLevel LogLevel = NBLogLevelDebug;
#else
static NBLogLevel LogLevel = NBLogLevelWarning;
#endif

@interface NBAccount ()

@property (nonatomic, weak, readwrite) id<NBAccountDelegate> delegate;
@property (nonatomic, strong, readwrite) NBClient *client;
@property (nonatomic, strong, readwrite) NSDictionary *clientInfo;
@property (nonatomic, strong, readwrite) NSDictionary *defaultClientInfo;

@property (nonatomic, strong) NBAuthenticator *authenticator;

@property (nonatomic, strong) NSDictionary *person;

- (NSURL *)baseURL;

- (void)fetchPersonWithCompletionHandler:(NBGenericCompletionHandler)completionHandler;
- (void)fetchAvatarWithCompletionHandler:(NBGenericCompletionHandler)completionHandler;

- (void)updateCredentialIdentifier;

@end

@implementation NBAccount

- (instancetype)initWithClientInfo:(NSDictionary *)clientInfoOrNil
                          delegate:(id<NBAccountDelegate>)delegate;
{
    self = [super init];
    if (self) {
        NSAssert(delegate, @"A delegate is required.");
        self.delegate = delegate;
        // Set defaults.
        self.shouldUseTestToken = NO;
        _identifier = NSNotFound;
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

#pragma mark - NBLogging

+ (void)updateLoggingToLevel:(NBLogLevel)logLevel
{
    LogLevel = logLevel;
}

#pragma mark - NBAccountViewDataSource

@synthesize avatarImageData = _avatarImageData;

- (NSString *)nationSlug
{
    return self.clientInfo[NBInfoNationNameKey];
}

#pragma mark - Public

#pragma mark Accessors

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
    self.client.delegate = self;
    return _client;
}

- (NBAuthenticator *)authenticator
{
    if (_authenticator) {
        return _authenticator;
    }
    self.authenticator = [[NBAuthenticator alloc] initWithBaseURL:[self baseURL]
                                                 clientIdentifier:self.clientInfo[NBInfoClientIdentifierKey]];
    self.authenticator.shouldAutomaticallySaveCredential = NO;
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
    // Guard.
    if (shouldUseTestToken == _shouldUseTestToken) { return; }
    NSAssert(self.clientInfo[NBInfoTestTokenKey], @"Invalid client info: test token required.");
    // Set.
    _shouldUseTestToken = shouldUseTestToken;
    // Did.
    self.client = nil;
}

- (NSURL *)baseURL
{
    return [NSURL URLWithString:
            [NSString stringWithFormat:self.clientInfo[NBInfoBaseURLFormatKey], self.clientInfo[NBInfoNationNameKey]]];
}

#pragma mark Presentation Helpers

@synthesize identifier = _identifier;
@synthesize name = _name;

- (NSString *)name
{
    if (!self.person) {
        return _name ?: nil;
    }
    NSString *name = self.person[@"username"];
    name = !!name && ![name isEqual:[NSNull null]] ? name : self.person[@"full_name"];
    return name;
}

- (void)setName:(NSString *)name
{
    _name = name;
    // Did.
    [self updateCredentialIdentifier];
}

- (NSUInteger)identifier
{
    if (_identifier != NSNotFound) {
        return _identifier;
    }
    if (self.person) {
        self.identifier = [self.person[@"id"] unsignedIntegerValue];
    }
    return _identifier;
}

- (void)setIdentifier:(NSUInteger)identifier
{
    _identifier = identifier;
    // Did.
    [self updateCredentialIdentifier];
}

#pragma mark Active API

- (void)requestActiveWithPriorSignout:(BOOL)needsPriorSignout
                    completionHandler:(NBGenericCompletionHandler)completionHandler
{
    [self.authenticator
     authenticateWithRedirectPath:self.clientInfo[NBInfoRedirectPathKey]
     priorSignout:needsPriorSignout
     completionHandler:^(NBAuthenticationCredential *credential, NSError *error) {
         if (error) {
             NBLogError(@"%@", error);
         } else if (credential) {
             // Success.
             NBLogInfo(@"Activating account for nation %@", self.clientInfo[NBInfoNationNameKey]);
             self.client.apiKey = credential.accessToken;
             self.active = YES;
             // TODO: This will be more robust with an NSOperationQueue.
             [self fetchPersonWithCompletionHandler:completionHandler];
             return;
         } else {
             NBLogWarning(@"Unhandled case.");
         }
         if (completionHandler) {
             completionHandler(error);
         }
     }];
}

- (BOOL)requestCleanUpWithError:(NSError *__autoreleasing *)error
{
    BOOL didDelete = [self.authenticator discardCredential];
    if (!didDelete) {
        *error =
        [NSError
         errorWithDomain:NBErrorDomain code:NBAuthenticationErrorCodeKeychain
         userInfo:@{ NSLocalizedDescriptionKey: @"message.delete-credential-error".nb_localizedString,
                     NSLocalizedFailureReasonErrorKey: @"message.unknown-error".nb_localizedString }];
    } else {
        self.client.apiKey = nil;
    }
    return didDelete;
}

#pragma mark - Private

- (void)fetchPersonWithCompletionHandler:(NBGenericCompletionHandler)completionHandler
{
    [self.client fetchPersonForClientUserWithCompletionHandler:^(NSDictionary *item, NSError *error) {
        if (error) {
            NBLogError(@"%@", error);
        } else if (item) {
            // Success.
            self.person = item;
            // Save credentials with custom ID.
            [self updateCredentialIdentifier];
            [NBAuthenticationCredential saveCredential:self.authenticator.credential
                                        withIdentifier:self.authenticator.credentialIdentifier];
            [self fetchAvatarWithCompletionHandler:completionHandler];
            return;
        } else {
            NBLogWarning(@"Unhandled case.");
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
            NBLogWarning(@"Invalid avatar URL %@", avatarURL.absoluteString);
        }
        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil);
            });
        }
    });
}

- (void)updateCredentialIdentifier
{
    if (![self.authenticator.credentialIdentifier isEqualToString:[self baseURL].host]) { return; }
    self.authenticator.credentialIdentifier =
    [self.authenticator.credentialIdentifier stringByAppendingString:
     ((self.name && self.identifier != NSNotFound) ? [NSString stringWithFormat:@"-%@-%lu", self.name, self.identifier] : @"")];
}

@end
