//
//  NBAuthenticator.m
//  NBClient
//
//  Created by Peng Wang on 7/10/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBAuthenticator.h"

#import "NBDefines.h"
#import "FoundationAdditions.h"

NSString * const NBAuthenticationGrantTypeCode = @"authorization_code";
NSString * const NBAuthenticationGrantTypeClientCredential = @"client_credentials";
NSString * const NBAuthenticationGrantTypePasswordCredential = @"password";
NSString * const NBAuthenticationGrantTypeRefresh = @"refresh_token";

NSUInteger const NBAuthenticationErrorCodeService = 20;

NSString * const NBAuthenticationRedirectTokenKey = @"token";

static NSString *CredentialServiceName = @"NBAuthenticationCredentialService";

@interface NBAuthenticator ()

@property (nonatomic, strong, readwrite) NSURL *baseURL;
@property (nonatomic, strong, readwrite) NSString *clientIdentifier;
@property (nonatomic, strong, readwrite) NSString *credentialIdentifier;
@property (nonatomic, strong, readwrite) NBAuthenticationCredential *credential;

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
    }
    return self;
}

#pragma mark - Accessors

@synthesize credential = _credential;

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
    // Boilerplate.
    static NSString *key;
    key = key ?: NSStringFromSelector(@selector(credential));
    [self willChangeValueForKey:key];
    _credential = credential;
    [self didChangeValueForKey:key];
    // END: Boilerplate.
    if (credential && self.shouldAutomaticallySaveCredential) {
        [NBAuthenticationCredential saveCredential:credential withIdentifier:self.credentialIdentifier];
    }
}

#pragma mark - Authenticate API

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
                                  skipPercentEncodingPairKeys:[NSSet setWithObject:@"username"]
                                   charactersToLeaveUnescaped:nil];
    
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:components.URL
                                                                  cachePolicy:NSURLRequestReloadRevalidatingCacheData
                                                              timeoutInterval:10.0f];
    mutableRequest.HTTPMethod = @"POST";
    [mutableRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [mutableRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSessionDataTask *task =
    [[NSURLSession sharedSession]
     dataTaskWithRequest:mutableRequest
     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
         NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
         if (data) {
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
             error = [NSError
                      errorWithDomain:NBErrorDomain
                      code:NBAuthenticationErrorCodeService
                      userInfo:@{ NSLocalizedDescriptionKey: [NSString localizedStringWithFormat:
                                                              NSLocalizedString(@"Service errored fulfilling request, status code: %ld", nil),
                                                              httpResponse.statusCode],
                                  NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Invalid status code:", nil),
                                  NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"If failure reasion is not helpful, "
                                                                                           @"contact NationBuilder for support.", nil) }];
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
             error = [NSError
                      errorWithDomain:NBErrorDomain
                      code:NBAuthenticationErrorCodeService
                      userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Service errored fulfilling request: %@", jsonObject[@"error"]),
                                  NSLocalizedFailureReasonErrorKey: (jsonObject[@"error_description"] ?
                                                                     jsonObject[@"error_description"] :
                                                                     NSLocalizedString(@"Reason unknown.", nil)),
                                  NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"If failure reasion is not helpful, "
                                                                                           @"contact NationBuilder for support.", nil) }];
         } else {
             self.credential = [[NBAuthenticationCredential alloc] initWithAccessToken:jsonObject[@"access_token"]
                                                                             tokenType:jsonObject[@"token_type"]];
         }
         if (completionHandler) {
             completionHandler(self.credential, error);
         }
     }];
    [task resume];
    
    return task;
}

@end

@implementation NBAuthenticationCredential

- (instancetype)initWithAccessToken:(NSString *)accessToken
                          tokenType:(NSString *)tokenType
{
    self = [super init];
    if (self) {
        self.accessToken = accessToken;
        self.tokenType = tokenType;
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
    if (status != errSecSuccess) {
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
    if (status != errSecSuccess) {
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
    if (status != errSecSuccess) {
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