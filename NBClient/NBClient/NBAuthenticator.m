//
//  NBAuthenticator.m
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import "NBAuthenticator.h"
#import "NBAuthenticator_Internal.h"

#import <UIKit/UIApplication.h>

#import "FoundationAdditions.h"

NSInteger const NBAuthenticationErrorCodeService = 20;
NSInteger const NBAuthenticationErrorCodeURLType = 21;
NSInteger const NBAuthenticationErrorCodeWebBrowser = 22;
NSInteger const NBAuthenticationErrorCodeKeychain = 23;
NSInteger const NBAuthenticationErrorCodeUser = 24;

NSString * const NBAuthenticationDefaultRedirectPath = @"oauth/callback";

// Private consts.

NSString * const NBAuthenticationGrantTypePasswordCredential = @"password";
NSString * const NBAuthenticationResponseTypeToken = @"token";

NSString * const NBAuthenticationRedirectURLIdentifier = @"com.nationbuilder.oauth";
NSString * const NBAuthenticationRedirectNotification = @"NBAuthenticationRedirectNotification";
NSString * const NBAuthenticationRedirectTokenKey = @"access_token";

static NSString *CredentialServiceName = @"NBAuthenticationCredentialService";
static NSString *RedirectURLScheme;

#if DEBUG
static NBLogLevel LogLevel = NBLogLevelDebug;
#else
static NBLogLevel LogLevel = NBLogLevelWarning;
#endif

// The implementations are heavily inspired by AFOAuth2Client.

@implementation NBAuthenticator

- (instancetype)initWithBaseURL:(NSURL *)baseURL
               clientIdentifier:(NSString *)clientIdentifier
{
    self = [super init];
    if (self) {
        self.baseURL = baseURL;
        self.clientIdentifier = clientIdentifier;
        self.shouldPersistCredential = YES;
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self
                   selector:@selector(finishAuthenticatingInWebBrowserWithNotification:)
                       name:NBAuthenticationRedirectNotification object:nil];
        [center addObserver:self
                   selector:@selector(finishAuthenticatingInWebBrowserWithNotification:)
                       name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:NBAuthenticationRedirectNotification object:nil];
    [center removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - NBLogging

+ (void)updateLoggingToLevel:(NBLogLevel)logLevel
{
    LogLevel = logLevel;
}

#pragma mark - Public

#pragma mark Accessors

@synthesize credential = _credential;

- (NBAuthenticationCredential *)credential
{
    if (_credential) {
        return _credential;
    }
    if (self.shouldPersistCredential) {
        self.credential = [NBAuthenticationCredential fetchCredentialWithIdentifier:self.credentialIdentifier];
    }
    return _credential;
}

- (void)setCredential:(NBAuthenticationCredential *)credential
{
    _credential = credential;
    // Did.
    if (credential && self.shouldPersistCredential) {
        [NBAuthenticationCredential saveCredential:credential withIdentifier:self.credentialIdentifier];
    }
}

- (BOOL)isAuthenticatingInWebBrowser
{
    return !!self.currentInBrowserAuthenticationCompletionHandler;
}

- (NSString *)credentialIdentifier
{
    if (_credentialIdentifier) {
        return _credentialIdentifier;
    }
    self.credentialIdentifier = self.defaultCredentialIdentifier;
    return _credentialIdentifier;
}

- (NSString *)defaultCredentialIdentifier
{
    return self.baseURL.host;
}

#pragma mark Authenticate API

- (void)authenticateWithRedirectPath:(NSString *)redirectPath
                        priorSignout:(BOOL)needsPriorSignout
                   completionHandler:(NBAuthenticationCompletionHandler)completionHandler
{
    NSAssert(completionHandler, @"Completion handler is required.");
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
        NBLogError(@"%@", error);
        completionHandler(nil, error);
        return;
    }
    self.currentlyNeedsPriorSignout = needsPriorSignout;
    NSDictionary *parameters = @{ @"response_type": NBAuthenticationResponseTypeToken,
                                  @"redirect_uri":  [NSString stringWithFormat:@"%@://%@",
                                                     self.class.authorizationRedirectApplicationURLScheme,
                                                     redirectPath] };
    [self
     authenticateWithSubPath:@"/authorize" parameters:parameters
     completionHandler:^(NBAuthenticationCredential *credential, NSError *error) {
         self.currentlyNeedsPriorSignout = NO;
         completionHandler(credential, error);
     }];
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
+ (BOOL)finishAuthenticatingInWebBrowserWithURL:(NSURL *)url
{
    BOOL didOpen = NO;
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:YES];
    if ([components.scheme isEqualToString:self.authorizationRedirectApplicationURLScheme]) {
        NSDictionary *parameters = [components.fragment nb_queryStringParametersWithEncoding:NSUTF8StringEncoding];
        NSString *accessToken = parameters[NBAuthenticationRedirectTokenKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:NBAuthenticationRedirectNotification object:nil
                                                          userInfo:@{ NBAuthenticationRedirectTokenKey: accessToken }];
        if (accessToken) {
            didOpen = YES;
        }
    }
    return didOpen;
}

#pragma mark - Private

- (NSURLSessionDataTask *)authenticateWithSubPath:(NSString *)subPath
                                       parameters:(NSDictionary *)parameters
                                completionHandler:(NBAuthenticationCompletionHandler)completionHandler
{
    NSAssert(completionHandler, @"Completion handler is required.");
    // Return saved credential if possible.
    if (self.credential) {
        completionHandler(self.credential, nil);
        return nil;
    }
    // Perform authentication against service.
    NSMutableDictionary *mutableParameters = [parameters mutableCopy];
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
    if (self.currentlyNeedsPriorSignout) {
        // NOTE: NSURLComponents was forming URLs that Safari would misinterpret by chopping off the path.
        NSString *escapedURLString = [url.absoluteString nb_percentEscapedQueryStringWithEncoding:NSASCIIStringEncoding
                                                                       charactersToLeaveUnescaped:nil];
        url = [NSURL URLWithString:[NSString stringWithFormat:@"/logout?url=%@", escapedURLString]
                     relativeToURL:self.baseURL];
        // NOTE: Safari seems to reject our relative URLs.
        url = url.absoluteURL;
    }
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
        NBLogInfo(@"Opening authentication URL in Safari: %@", url);
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
    // Check our state.
    if (!self.isAuthenticatingInWebBrowser) { return; }
    NBAuthenticationCredential *credential;
    NSError *error;
    if (notification.name == UIApplicationDidBecomeActiveNotification) {
        // Handle user manually stopping authorization flow, ie. manually
        // switching back to app before authorization.
        error = [NSError
                 errorWithDomain:NBErrorDomain
                 code:NBAuthenticationErrorCodeUser
                 userInfo:@{ NSLocalizedDescriptionKey: @"message.redirect-error".nb_localizedString,
                             NSLocalizedFailureReasonErrorKey: @"message.redirect-error.user-stopped".nb_localizedString,
                             NSLocalizedRecoverySuggestionErrorKey: @"message.redirect-error.sign-in-again".nb_localizedString }];
    } else if (notification.name == NBAuthenticationRedirectNotification) {
        // Check our notification.
        if (!notification.userInfo[NBAuthenticationRedirectTokenKey]) {
            error = [NSError
                     errorWithDomain:NBErrorDomain
                     code:NBAuthenticationErrorCodeService
                     userInfo:@{ NSLocalizedDescriptionKey: @"message.nb-redirect-error".nb_localizedString,
                                 NSLocalizedFailureReasonErrorKey: @"message.nb-redirect-error.no-access-token".nb_localizedString,
                                 NSLocalizedRecoverySuggestionErrorKey: @"message.unknown-error-solution".nb_localizedString }];
        } else {
            // Handle normal completion of authorization flow.
            credential = [[NBAuthenticationCredential alloc] initWithAccessToken:notification.userInfo[NBAuthenticationRedirectTokenKey]
                                                                       tokenType:nil];
            self.credential = credential;
        }
    }
    // Complete.
    self.currentInBrowserAuthenticationCompletionHandler(credential, error);
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
         if (data) {
             NBLogInfo(@"RESPONSE: %@\nBODY: %@", httpResponse, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
         }
         // Handle data task error.
         if (error) {
             NBLogError(@"%@", error);
             if (completionHandler) { completionHandler(nil, error); }
             return;
         }
         // Handle HTTP error.
         if (![[NSIndexSet nb_indexSetOfSuccessfulHTTPStatusCodes] containsIndex:(NSUInteger)httpResponse.statusCode]) {
             error =
             [NSError
              errorWithDomain:NBErrorDomain
              code:NBAuthenticationErrorCodeService
              userInfo:@{ NSLocalizedDescriptionKey: [NSString localizedStringWithFormat:@"message.http-error.format".nb_localizedString,
                                                      httpResponse.statusCode],
                          NSLocalizedFailureReasonErrorKey: @"message.invalid-status-code".nb_localizedString,
                          NSLocalizedRecoverySuggestionErrorKey: @"message.unknown-error-solution".nb_localizedString }];
             NBLogError(@"%@", error);
             if (completionHandler) { completionHandler(nil, error); }
             return;
         }
         NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                    options:NSJSONReadingAllowFragments
                                                                      error:&error];
         // Handle JSON error.
         if (error) {
             NBLogError(@"%@", error);
             if (completionHandler) { completionHandler(nil, error); }
             return;
         }
         // Handle Non-HTTP error.
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
             NBLogError(@"%@", error);
         } else {
             self.credential = [[NBAuthenticationCredential alloc] initWithAccessToken:jsonObject[@"access_token"]
                                                                             tokenType:jsonObject[@"token_type"]];
         }
         // Completed. Successful if error is nil.
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
    if (!credential) { return didSave; }
    // Setup dictionaries.
    NSMutableDictionary *query = [self baseKeychainQueryDictionaryWithIdentifier:identifier];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[(__bridge id)kSecValueData] = [NSKeyedArchiver archivedDataWithRootObject:credential];
    dictionary[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleWhenUnlocked;
    // Update else create.
    OSStatus status;
    NBLogInfo(@"Fetching existing keychain credential...");
    BOOL alreadyExists = [self fetchCredentialWithIdentifier:identifier] != nil;
    if (alreadyExists) {
        status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)dictionary);
    } else {
        [query addEntriesFromDictionary:dictionary];
        status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    }
    // Handle error.
    if (status != errSecSuccess) {
        NBLogInfo(@"Unable to %@ credential in keychain with identifier \"%@\" (Error %li)",
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
    if (status != errSecSuccess) {
        NBLogInfo(@"Unable to delete from keychain credential with identifier \"%@\" (Error %li)",
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
    if (status != errSecSuccess) {
        NBLogInfo(@"Unable to fetch from keychain credential with identifier \"%@\" (Error %li)",
                  identifier, (long int)status);
        return nil;
    }
    // Convert.
    NSData *data = (__bridge_transfer NSData *)result;
    NBAuthenticationCredential *credential = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NBLogInfo(@"Fetched keychain credential with identifier \"%@\"", identifier);
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
