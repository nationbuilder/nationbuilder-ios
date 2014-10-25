//
//  NBAuthenticator.m
//  NBClient
//
//  Created by Peng Wang on 7/10/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBAuthenticator.h"

#import <UIKit/UIApplication.h>

#import "FoundationAdditions.h"

NSUInteger const NBAuthenticationErrorCodeService = 20;
NSUInteger const NBAuthenticationErrorCodeURLType = 21;
NSUInteger const NBAuthenticationErrorCodeWebBrowser = 22;
NSUInteger const NBAuthenticationErrorCodeKeychain = 23;

NSString * const NBAuthenticationDefaultRedirectPath = @"oauth/callback";

// Private consts.

NSString * const NBAuthenticationGrantTypePasswordCredential = @"password";
NSString * const NBAuthenticationResponseTypeToken = @"token";

NSString * const NBAuthenticationRedirectURLIdentifier = @"com.nationbuilder.oauth";
NSString * const NBAuthenticationRedirectNotification = @"NBAuthenticationRedirectNotification";
NSString * const NBAuthenticationRedirectTokenKey = @"access_token";

static NSString *CredentialServiceName = @"NBAuthenticationCredentialService";
static NSString *RedirectURLScheme;

#ifdef DEBUG
static NBLogLevel LogLevel = NBLogLevelDebug;
#else
static NBLogLevel LogLevel = NBLogLevelWarning;
#endif

@interface NBAuthenticator ()

@property (nonatomic, strong, readwrite) NSURL *baseURL;
@property (nonatomic, strong, readwrite) NSString *clientIdentifier;
@property (nonatomic, strong, readwrite) NSString *credentialIdentifier;
@property (nonatomic, strong, readwrite) NBAuthenticationCredential *credential;

@property (nonatomic, strong) NBAuthenticationCompletionHandler currentInBrowserAuthenticationCompletionHandler;

- (NSURLSessionDataTask *)authenticateWithSubPath:(NSString *)subPath
                                       parameters:(NSDictionary *)parameters
                                completionHandler:(NBAuthenticationCompletionHandler)completionHandler;

- (void)authenticateInWebBrowserWithURL:(NSURL *)url
                      completionHandler:(NBAuthenticationCompletionHandler)completionHandler;
- (void)finishAuthenticatingInWebBrowserWithNotification:(NSNotification *)notification;

- (NSURLSessionDataTask *)authenticationDataTaskWithURL:(NSURL *)url
                                      completionHandler:(NBAuthenticationCompletionHandler)completionHandler;

@end

@interface NBAuthenticationCredential ()

@property (nonatomic, strong, readwrite) NSString *accessToken;
@property (nonatomic, strong, readwrite) NSString *tokenType;

+ (NSMutableDictionary *)baseKeychainQueryDictionaryWithIdentifier:(NSString *)identifier;

@end

// The implementations are heavily inspired by AFOAuth2Client.

@implementation NBAuthenticator

- (instancetype)initWithBaseURL:(NSURL *)baseURL
               clientIdentifier:(NSString *)clientIdentifier
{
    self = [super init];
    if (self) {
        self.baseURL = baseURL;
        self.clientIdentifier = clientIdentifier;
        self.credentialIdentifier = self.baseURL.host;
        self.shouldAutomaticallySaveCredential = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(finishAuthenticatingInWebBrowserWithNotification:)
                                                     name:NBAuthenticationRedirectNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NBAuthenticationRedirectNotification object:nil];
}

#pragma mark - NBLogging

+ (void)updateLoggingToLevel:(NBLogLevel)logLevel
{
    LogLevel = logLevel;
}

#pragma mark - Accessors

@synthesize credential = _credential; // TODO: This shouldn't be needed.

- (NBAuthenticationCredential *)credential
{
    if (_credential) {
        return _credential;
    }
    self.credential = [NBAuthenticationCredential fetchCredentialWithIdentifier:self.credentialIdentifier];
    return _credential;
}

- (void)setCredential:(NBAuthenticationCredential *)credential
{
    _credential = credential;
    // Did.
    if (credential && self.shouldAutomaticallySaveCredential) {
        [NBAuthenticationCredential saveCredential:credential withIdentifier:self.credentialIdentifier];
    }
}

- (BOOL)isAuthenticatingInWebBrowser
{
    return !!self.currentInBrowserAuthenticationCompletionHandler;
}

#pragma mark Authenticate API

- (void)authenticateWithRedirectPath:(NSString *)redirectPath
                   completionHandler:(NBAuthenticationCompletionHandler)completionHandler
{
    if (!self.class.authorizationRedirectApplicationURLScheme) {
        NSError *error =
        [NSError
         errorWithDomain:NBErrorDomain
         code:NBAuthenticationErrorCodeURLType
         userInfo:@{ NSLocalizedDescriptionKey: @"message.invalid-redirect-url-scheme.none".nb_localizedString,
                     NSLocalizedFailureReasonErrorKey: [NSString localizedStringWithFormat:
                                                        @"message.invalid-redirect-url-scheme.no-url-type.format".nb_localizedString,
                                                        NBAuthenticationRedirectURLIdentifier],
                     NSLocalizedRecoverySuggestionErrorKey: [NSString localizedStringWithFormat:
                                                             @"message.invalid-redirect-url-scheme.suggestion".nb_localizedString,
                                                             NBAuthenticationRedirectURLIdentifier] }];
        completionHandler(nil, error);
    }
    NSDictionary *parameters = @{ @"response_type": NBAuthenticationResponseTypeToken,
                                  @"redirect_uri":  [NSString stringWithFormat:@"%@://%@",
                                                     self.class.authorizationRedirectApplicationURLScheme,
                                                     redirectPath] };
    [self authenticateWithSubPath:@"/authorize" parameters:parameters completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)authenticateWithUserName:(NSString *)userName
                                          password:(NSString *)password
                                      clientSecret:(NSString *)clientSecret
                                 completionHandler:(NBAuthenticationCompletionHandler)completionHandler
{
    NSDictionary *parameters = @{ @"grant_type": NBAuthenticationGrantTypePasswordCredential,
                                  @"client_secret": clientSecret,
                                  @"username": userName,
                                  @"password": password };
    return [self authenticateWithSubPath:@"/token" parameters:parameters completionHandler:completionHandler];
}

- (BOOL)discardCredential
{
    self.credential = nil;
    return [NBAuthenticationCredential deleteCredentialWithIdentifier:self.credentialIdentifier];
}

+ (NSString *)authorizationRedirectApplicationURLScheme
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *urlTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
        for (NSDictionary *type in urlTypes) {
            if ([type[@"CFBundleURLName"] isEqualToString:NBAuthenticationRedirectURLIdentifier]) {
                RedirectURLScheme = [type[@"CFBundleURLSchemes"] firstObject];
                break;
            }
        }
    });
    return RedirectURLScheme;
}

// Since this is a stateless method, decoupled from any one authenticator, it
// must rely on notifications.
+ (BOOL)finishAuthenticatingInWebBrowserWithURL:(NSURL *)url error:(NSError *__autoreleasing *)error
{
    BOOL didOpen = NO;
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    if ([components.scheme isEqualToString:self.authorizationRedirectApplicationURLScheme]) {
        NSDictionary *parameters = [components.fragment nb_queryStringParametersWithEncoding:NSUTF8StringEncoding];
        NSString *accessToken = parameters[NBAuthenticationRedirectTokenKey];
        if (accessToken) {
            [[NSNotificationCenter defaultCenter] postNotificationName:NBAuthenticationRedirectNotification object:nil
                                                              userInfo:@{ NBAuthenticationRedirectTokenKey: accessToken }];
            didOpen = YES;
        } else {
            *error = [NSError
                      errorWithDomain:NBErrorDomain
                      code:NBAuthenticationErrorCodeService
                      userInfo:@{ NSLocalizedDescriptionKey: @"message.nb-redirect-error".nb_localizedString,
                                  NSLocalizedFailureReasonErrorKey: @"message.nb-redirect-error.no-access-token".nb_localizedString,
                                  NSLocalizedRecoverySuggestionErrorKey: @"message.unknown-error-solution".nb_localizedString }];
        }
    }
    return didOpen;
}

#pragma mark - Private

- (NSURLSessionDataTask *)authenticateWithSubPath:(NSString *)subPath
                                       parameters:(NSDictionary *)parameters
                                completionHandler:(NBAuthenticationCompletionHandler)completionHandler
{
    // Return saved credential if possible.
    if (self.credential) {
        completionHandler(self.credential, nil);
        return nil;
    }
    // Perform authentication against service.
    NSMutableDictionary *mutableParameters = parameters.mutableCopy;
    mutableParameters[@"client_id"] = self.clientIdentifier;
    parameters = [NSDictionary dictionaryWithDictionary:mutableParameters];
    
    NSURLComponents *components =
    [NSURLComponents componentsWithURL:[NSURL URLWithString:[@"/oauth" stringByAppendingPathComponent:subPath]
                                              relativeToURL:self.baseURL]
               resolvingAgainstBaseURL:YES];
    
    components.query = [parameters nb_queryStringWithEncoding:NSASCIIStringEncoding
                                  skipPercentEncodingPairKeys:[NSSet setWithObjects:@"username", @"redirect_uri", nil]
                                   charactersToLeaveUnescaped:nil];
    
    NSURLSessionDataTask *task;
    NSURL *url = components.URL;
    if (parameters[@"response_type"] == NBAuthenticationResponseTypeToken) {
        [self authenticateInWebBrowserWithURL:url completionHandler:completionHandler];
    } else if (parameters[@"grant_type"] == NBAuthenticationGrantTypePasswordCredential) {
        task = [self authenticationDataTaskWithURL:url completionHandler:completionHandler];
        [task resume];
    }
    return task;
}

- (void)authenticateInWebBrowserWithURL:(NSURL *)url completionHandler:(NBAuthenticationCompletionHandler)completionHandler
{
    UIApplication *application = [UIApplication sharedApplication];
    NSError *error;
    if ([application canOpenURL:url]) {
        self.currentInBrowserAuthenticationCompletionHandler = completionHandler;
        dispatch_async(dispatch_get_main_queue(), ^{
            [application openURL:url];
        });
    } else {
        error = [NSError
                 errorWithDomain:NBErrorDomain
                 code:NBAuthenticationErrorCodeWebBrowser
                 userInfo:@{ NSLocalizedDescriptionKey: @"message.invalid-browser".nb_localizedString,
                             NSLocalizedFailureReasonErrorKey: @"message.invalid-browser.auth-requires-browser".nb_localizedString,
                             NSLocalizedRecoverySuggestionErrorKey: @"message.invalid-browser.check-safari-installed".nb_localizedString }];
    }
    if (error) {
        completionHandler(nil, error);
    }
}

- (void)finishAuthenticatingInWebBrowserWithNotification:(NSNotification *)notification
{
    if (!self.isAuthenticatingInWebBrowser || !notification.userInfo[NBAuthenticationRedirectTokenKey]) {
        return;
    }
    self.credential = [[NBAuthenticationCredential alloc] initWithAccessToken:notification.userInfo[NBAuthenticationRedirectTokenKey]
                                                                    tokenType:nil];
    self.currentInBrowserAuthenticationCompletionHandler(self.credential, nil);
    self.currentInBrowserAuthenticationCompletionHandler = nil;
}


- (NSURLSessionDataTask *)authenticationDataTaskWithURL:(NSURL *)url
                                      completionHandler:(NBAuthenticationCompletionHandler)completionHandler
{
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:url
                                                                  cachePolicy:NSURLRequestReloadRevalidatingCacheData
                                                              timeoutInterval:10.0f];
    mutableRequest.HTTPMethod = @"POST";
    [mutableRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [mutableRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    

    return [[NSURLSession sharedSession]
     dataTaskWithRequest:mutableRequest
     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
         NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
         if (data && LogLevel >= NBLogLevelInfo) {
             NSLog(@"RESPONSE: %@\n"
                   @"BODY: %@",
                   httpResponse,
                   [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
         }
         // Handle data task error.
         if (error) {
             if (completionHandler) {
                 completionHandler(nil, error);
             }
             return;
         }
         // Handle HTTP error.
         if (![[NSIndexSet nb_indexSetOfSuccessfulHTTPStatusCodes] containsIndex:httpResponse.statusCode]) {
             error =
             [NSError
              errorWithDomain:NBErrorDomain
              code:NBAuthenticationErrorCodeService
              userInfo:@{ NSLocalizedDescriptionKey: [NSString localizedStringWithFormat:@"message.http-error.format".nb_localizedString,
                                                      httpResponse.statusCode],
                          NSLocalizedFailureReasonErrorKey: @"message.invalid-status-code".nb_localizedString,
                          NSLocalizedRecoverySuggestionErrorKey: @"message.unknown-error-solution".nb_localizedString }];
             if (completionHandler) {
                 completionHandler(nil, error);
             }
             return;
         }
         NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                    options:NSJSONReadingAllowFragments
                                                                      error:&error];
         // Handle JSON error.
         if (error) {
             if (completionHandler) {
                 completionHandler(nil, error);
             }
             return;
         }
         if (jsonObject[@"error"]) {
             error =
             [NSError
              errorWithDomain:NBErrorDomain
              code:NBAuthenticationErrorCodeService
              userInfo:@{ NSLocalizedDescriptionKey: [NSString localizedStringWithFormat:@"message.request-error.format".nb_localizedString,
                                                      jsonObject[@"error"]],
                          NSLocalizedFailureReasonErrorKey: (jsonObject[@"error_description"] ?
                                                             jsonObject[@"error_description"] : @"message.unknown-error-reason".nb_localizedString),
                          NSLocalizedRecoverySuggestionErrorKey: @"message.unknown-error-solution".nb_localizedString }];
         } else {
             self.credential = [[NBAuthenticationCredential alloc] initWithAccessToken:jsonObject[@"access_token"]
                                                                             tokenType:jsonObject[@"token_type"]];
         }
         if (completionHandler) {
             completionHandler(self.credential, error);
         }
     }];
}

@end

@implementation NBAuthenticationCredential

- (instancetype)initWithAccessToken:(NSString *)accessToken
                          tokenType:(NSString *)tokenTypeOrNil
{
    self = [super init];
    if (self) {
        self.accessToken = accessToken;
        self.tokenType = tokenTypeOrNil ? tokenTypeOrNil : @"bearer";
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<accessToken: %@ tokenType: %@>", self.accessToken, self.tokenType];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.accessToken = [aDecoder decodeObjectForKey:@"accessToken"];
        self.tokenType = [aDecoder decodeObjectForKey:@"tokenType"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.accessToken forKey:@"accessToken"];
    [aCoder encodeObject:self.tokenType forKey:@"tokenType"];
}

#pragma mark - Keychain

+ (BOOL)saveCredential:(NBAuthenticationCredential *)credential
        withIdentifier:(NSString *)identifier
{
    BOOL didSave = NO;
    // Handle saving nil.
    if (!credential) {
        return [self deleteCredentialWithIdentifier:identifier];
    }
    // Setup dictionaries.
    NSMutableDictionary *query = [self baseKeychainQueryDictionaryWithIdentifier:identifier];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[(__bridge id)kSecValueData] = [NSKeyedArchiver archivedDataWithRootObject:credential];
    dictionary[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleWhenUnlocked;
    // Update else create.
    OSStatus status;
    BOOL alreadyExists = [self fetchCredentialWithIdentifier:identifier] != nil;
    if (alreadyExists) {
        status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)dictionary);
    } else {
        [query addEntriesFromDictionary:dictionary];
        status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    }
    // Handle error.
    if (status != errSecSuccess && LogLevel >= NBLogLevelError) {
        NSLog(@"Unable to %@ credential in keychain with identifier \"%@\" (Error %li)",
              alreadyExists ? @"update" : @"create", identifier, (long int)status);
    } else {
        didSave = YES;
    }
    return didSave;
}

+ (BOOL)deleteCredentialWithIdentifier:(NSString *)identifier
{
    BOOL didDelete = NO;
    NSMutableDictionary *query = [self baseKeychainQueryDictionaryWithIdentifier:identifier];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    if (status != errSecSuccess && LogLevel >= NBLogLevelError) {
        NSLog(@"Unable to delete from keychain credential with identifier \"%@\" (Error %li)",
              identifier, (long int)status);
    } else {
        didDelete = YES;
    }
    return didDelete;
}

+ (NBAuthenticationCredential *)fetchCredentialWithIdentifier:(NSString *)identifier
{
    NSMutableDictionary *query = [self baseKeychainQueryDictionaryWithIdentifier:identifier];
    query[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    CFDataRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    // Handle errors.
    if (status != errSecSuccess && LogLevel >= NBLogLevelError) {
        NSLog(@"Unable to fetch from keychain credential with identifier \"%@\" (Error %li)",
              identifier, (long int)status);
        return nil;
    }
    // Convert.
    NSData *data = (__bridge_transfer NSData *)result;
    NBAuthenticationCredential *credential = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    return credential;
}

#pragma mark - Private

+ (NSMutableDictionary *)baseKeychainQueryDictionaryWithIdentifier:(NSString *)identifier
{
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    query[(__bridge id)kSecAttrService] = CredentialServiceName;
    query[(__bridge id)kSecAttrAccount] = identifier;
    return query;
}

@end