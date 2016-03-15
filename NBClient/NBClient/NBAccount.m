//
//  NBAccount.m
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBAccount.h"
#import "NBAccount_Internal.h"

#import "FoundationAdditions.h"
#import "NBAuthenticator.h"
#import "NBClient.h"
#import "NBClient+People.h"

#if DEBUG
static NBLogLevel LogLevel = NBLogLevelDebug;
#else
static NBLogLevel LogLevel = NBLogLevelWarning;
#endif

@implementation NBAccount

- (instancetype)initWithClientInfo:(NSDictionary *)clientInfoOrNil
                          delegate:(id<NBAccountDelegate>)delegate;
{
    self = [super init];
    if (self) {
        NSAssert(delegate, @"A delegate is required.");
        self.delegate = delegate;
        // Set defaults.
        self.shouldAutoFetchAvatar = YES;
        self.shouldUseTestToken = NO;
        _identifier = NSNotFound;
        if (!clientInfoOrNil) {
            clientInfoOrNil = self.defaultClientInfo;
        }
        NSMutableDictionary *mutableClientInfo = clientInfoOrNil.mutableCopy;
        // Fill in OAuth client ID if needed.
        mutableClientInfo[NBInfoClientIdentifierKey] = mutableClientInfo[NBInfoClientIdentifierKey] ?: self.defaultClientInfo[NBInfoClientIdentifierKey];
        // Check for developer.
        NSAssert(mutableClientInfo[NBInfoNationSlugKey] && mutableClientInfo[NBInfoClientIdentifierKey],
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
@synthesize shouldAutoFetchAvatar = _shouldAutoFetchAvatar;

- (NSString *)nationSlug
{
    return self.clientInfo[NBInfoNationSlugKey];
}

#pragma mark - NBClientDelegate

- (BOOL)client:(NBClient *)client shouldHandleResponse:(NSHTTPURLResponse *)response
                                            forRequest:(NSURLRequest *)request
                                         withHTTPError:(NSError *)error
{
    if (response.statusCode == 401 && client.apiKey) {
        NBLogInfo(@"Account reported as unauthorized, access token: %@", client.apiKey);
        NSError *cleanUpError;
        BOOL didCleanUp = [self requestCleanUpWithError:&cleanUpError];
        if (!didCleanUp) {
            NBLogError(@"Account cleanup failed with error: %@", cleanUpError);
            return YES;
        }
        [self.delegate account:self didBecomeInvalidFromHTTPError:error];
        return NO;
    }
    return YES;
}

#pragma mark - Public

#pragma mark Accessors

- (NBClient *)client
{
    if (_client) {
        return _client;
    }
    if (self.shouldUseTestToken) {
        self.client = [[NBClient alloc] initWithNationSlug:self.clientInfo[NBInfoNationSlugKey]
                                                    apiKey:self.clientInfo[NBInfoTestTokenKey]
                                             customBaseURL:self.baseURL
                                          customURLSession:nil customURLSessionConfiguration:nil];
    } else {
        self.client = [[NBClient alloc] initWithNationSlug:self.clientInfo[NBInfoNationSlugKey]
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
    self.authenticator = [[NBAuthenticator alloc] initWithBaseURL:self.baseURL
                                                 clientIdentifier:self.clientInfo[NBInfoClientIdentifierKey]];
    self.authenticator.shouldPersistCredential = NO;
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
            [NSString stringWithFormat:self.clientInfo[NBInfoBaseURLFormatKey], self.clientInfo[NBInfoNationSlugKey]]];
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
    void (^authenticationCompletionHandler)(NBAuthenticationCredential *, NSError *) = ^(NBAuthenticationCredential *credential, NSError *error) {
        if (error) {
            NBLogError(@"%@", error);
        } else if (credential) {
            // Success.
            NBLogInfo(@"Activating account for nation %@", self.clientInfo[NBInfoNationSlugKey]);
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
    };
    // Return saved credential if possible.
    NBAuthenticationCredential *credential;
    if (self.authenticator.credential) {
        credential = self.authenticator.credential;
    } else {
        BOOL didUpdate = [self updateCredentialIdentifier];
        if (didUpdate) {
            credential = [NBAuthenticationCredential fetchCredentialWithIdentifier:self.authenticator.credentialIdentifier];
        }
    }
    if (credential) {
        authenticationCompletionHandler(credential, nil);
        return;
    }
    // Authenticate.
    [self.authenticator
     authenticateWithRedirectPath:self.clientInfo[NBInfoRedirectPathKey]
     priorSignout:needsPriorSignout
     completionHandler:authenticationCompletionHandler];
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
            if (self.shouldAutoFetchAvatar) {
                [self fetchAvatarWithCompletionHandler:completionHandler];
            } else {
                completionHandler(nil);
            }
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
    NSURLSessionDownloadTask *avatarTask =
    [self.client.urlSession
     downloadTaskWithURL:avatarURL completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
         self.avatarImageData = [NSData dataWithContentsOfURL:location];
         if (!self.avatarImageData) {
             NBLogWarning(@"Invalid avatar URL %@", avatarURL);
         }
         if (completionHandler) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 completionHandler(nil);
             });
         }
     }];
    [avatarTask resume];
}

- (BOOL)updateCredentialIdentifier
{
    BOOL didUpdate = NO;
    if (self.name && self.identifier != NSNotFound) {
        self.authenticator.credentialIdentifier =
        [self.authenticator.defaultCredentialIdentifier stringByAppendingString:
         [NSString stringWithFormat:@"-%@-%lu", self.name, (unsigned long)self.identifier]];
        didUpdate = YES;
    }
    return didUpdate;
}

@end
