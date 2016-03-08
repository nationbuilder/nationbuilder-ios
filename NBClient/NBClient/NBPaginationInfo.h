//
//  NBPaginationInfo.h
//  NBClient
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NBDefines.h"

extern NSString * __nonnull const NBClientCurrentPageNumberKey; // #legacy
extern NSString * __nonnull const NBClientNumberOfTotalPagesKey; // #legacy
extern NSString * __nonnull const NBClientNumberOfItemsPerPageKey;
extern NSString * __nonnull const NBClientNumberOfTotalItemsKey; // #legacy

extern NSString * __nonnull const NBClientPaginationLimitKey;
extern NSString * __nonnull const NBClientPaginationNextLinkKey;
extern NSString * __nonnull const NBClientPaginationPreviousLinkKey;

typedef NS_ENUM(NSUInteger, NBPaginationDirection) {
    NBPaginationDirectionNext,
    NBPaginationDirectionPrevious,
};

@interface NBPaginationInfo : NSObject <NBDictionarySerializing, NBLogging>

// NOTE: Using the legacy NationBuilder API pagination is discouraged. Outside
// of test tokens and older applications, it has been deprecated and the new
// token-based pagination should be used. The constants, properties, and
// methods tagged with #legacy are part of the legacy pagination.

@property (nonatomic) NSUInteger currentPageNumber; // Starts at 1.
@property (nonatomic) NSUInteger numberOfItemsPerPage;
@property (nonatomic) NSUInteger numberOfTotalPages; // #legacy
@property (nonatomic) NSUInteger numberOfTotalItems; // #legacy

@property (nonatomic) NSUInteger numberOfTotalAvailableItems;

@property (nonatomic, getter = isLegacy) BOOL legacy;

@property (nonatomic, copy, nullable) NSString *nextPageURLString;
@property (nonatomic, copy, nullable) NSString *previousPageURLString;
@property (nonatomic) NBPaginationDirection currentDirection;

@property (nonatomic, readonly) BOOL isLastPage;

- (NSUInteger)indexOfFirstItemAtPage:(NSUInteger)pageNumber;
- (NSUInteger)numberOfItemsAtPage:(NSUInteger)pageNumber;

- (nonnull NSDictionary *)queryParameters;

// Designated initializer.
- (nonnull instancetype)initWithDictionary:(nullable NSDictionary *)dictionary legacy:(BOOL)legacy;

- (void)updateCurrentPageNumber;

+ (BOOL)dictionaryContainsPaginationInfo:(nonnull NSDictionary *)dictionary;

@end
