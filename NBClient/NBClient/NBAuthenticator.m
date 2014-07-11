//
//  NBAuthenticator.m
//  NBClient
//
//  Created by Peng Wang on 7/10/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBAuthenticator.h"

#import "NBDefines.h"

@interface NBAuthenticator ()

@property (strong, nonatomic, readwrite) NSURL *baseURL;
@property (strong, nonatomic, readwrite) NSString *clientIdentifier;

@property (strong, nonatomic) NSString *clientSecret;

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

@end