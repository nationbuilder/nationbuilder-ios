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

NSUInteger const NBAuthenticationErrorCodeService = 1;

@interface NBAuthenticator ()

@property (strong, nonatomic, readwrite) NSURL *baseURL;
@property (strong, nonatomic, readwrite) NSString *clientIdentifier;

@property (strong, nonatomic) NSString *clientSecret;

@end

@interface NBAuthenticationCredential ()

@property (strong, nonatomic, readwrite) NSString *accessToken;
@property (strong, nonatomic, readwrite) NSString *tokenType;

@end

// The implementation is heavily inspired by AFOAuth2Client.

@implementation NBAuthenticator

- (instancetype)initWithBaseURL:(NSURL *)baseURL
               clientIdentifier:(NSString *)clientIdentifier
                   clientSecret:(NSString *)clientSecret
{
    self = [super init];
    if (self) {
        self.baseURL = baseURL;
        self.clientIdentifier = clientIdentifier;
        self.clientSecret = clientSecret;
    }
    return self;
}

#pragma mark - Authenticate API

- (NSURLSessionDataTask *)authenticateWithUserName:(NSString *)userName
                                          password:(NSString *)password
                                 completionHandler:(NBAuthenticationCompletionHandler)completionHandler
{
    NSDictionary *parameters = @{ @"grant_type": NBAuthenticationGrantTypePasswordCredential,
                                  @"username": userName,
                                  @"password": password };
    return [self authenticateWithSubPath:@"/token" parameters:parameters completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)authenticateWithSubPath:(NSString *)subPath
                                       parameters:(NSDictionary *)parameters
                                completionHandler:(NBAuthenticationCompletionHandler)completionHandler
{
    NSMutableDictionary *mutableParameters = parameters.mutableCopy;
    mutableParameters[@"client_id"] = self.clientIdentifier;
    mutableParameters[@"client_secret"] = self.clientSecret;
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
                                                              NSLocalizedString(@"Service errored fulfilling request, status code: %d", nil),
                                                              httpResponse.statusCode],
                                  NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Invalid status code:", nil),
                                  NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"If failure reasion is not helpful, "
                                                                                           @"contact NationBuilder for support.", nil) }];
             if (completionHandler) {
                 completionHandler(nil, error);
             }
             return;
         }
         NBAuthenticationCredential *credential;
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
             credential = [[NBAuthenticationCredential alloc] init];
             credential.accessToken = jsonObject[@"access_token"];
             credential.tokenType = jsonObject[@"token_type"];
         }
         if (completionHandler) {
             completionHandler(credential, error);
         }
     }];
    [task resume];
    
    return task;
}

@end

@implementation NBAuthenticationCredential

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ access token: %@", self.tokenType, self.accessToken];
}

@end