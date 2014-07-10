//
//  NBAuthenticator.h
//  NBClient
//
//  Created by Peng Wang on 7/10/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NBAuthenticator : NSObject

@property (strong, nonatomic, readonly) NSURL *baseURL;
@property (strong, nonatomic, readonly) NSString *clientIdentifier;

- (instancetype)initWithBaseURL:(NSURL *)baseURL
               clientIdentifier:(NSString *)clientIdentifier
                   clientSecret:(NSString *)clientSecret;

@end
