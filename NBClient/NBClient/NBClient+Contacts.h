//
//  NBClient+Contacts.h
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBClient.h"

@interface NBClient (Contacts)

/**
 Contacts & Contact Types
 
 The endpoint annotations are for reference only to link to the API docs and may
 change independently of the method selectors below.
 
 The order of the methods listing attempts to mirror that of apiexplorer.nationbuilder.com.
 */

#pragma mark - Contacts

// GET /people/:person_id/contacts
- (nonnull NSURLSessionDataTask *)fetchPersonContactsByIdentifier:(NSUInteger)personIdentifier
                                               withPaginationInfo:(nullable NBPaginationInfo *)paginationInfo
                                                completionHandler:(nonnull NBClientResourceListCompletionHandler)completionHandler;

// POST /people/:person_id/contacts
- (nullable NSURLSessionDataTask *)createPersonContactByIdentifier:(NSUInteger)personIdentifier
                                                   withContactInfo:(nonnull NSDictionary *)contactInfo
                                                 completionHandler:(nonnull NBClientResourceItemCompletionHandler)completionHandler;

#pragma mark - Contact Types (Fetch Only)

// GET /settings/contact_types
- (nonnull NSURLSessionDataTask *)fetchContactTypesWithPaginationInfo:(nullable NBPaginationInfo *)paginationInfo
                                                    completionHandler:(nonnull NBClientResourceListCompletionHandler)completionHandler;

// GET /settings/contact_methods
- (nonnull NSURLSessionDataTask *)fetchContactMethodsWithCompletionHandler:(nonnull NBClientResourceListCompletionHandler)completionHandler;

// GET /settings/contact_statuses
- (nonnull NSURLSessionDataTask *)fetchContactStatusesWithCompletionHandler:(nonnull NBClientResourceListCompletionHandler)completionHandler;

@end
