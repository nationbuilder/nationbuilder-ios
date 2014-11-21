//
//  NBPaginationInfo.m
//  NBClient
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBPaginationInfo.h"

#import "FoundationAdditions.h"

NSString * const NBClientCurrentPageNumberKey = @"page";
NSString * const NBClientNumberOfTotalPagesKey = @"total_pages";
NSString * const NBClientNumberOfItemsPerPageKey = @"per_page";
NSString * const NBClientNumberOfTotalItemsKey = @"total";

NSString * const NBClientPaginationLimitKey = @"limit";
NSString * const NBClientPaginationNextLinkKey = @"next";
NSString * const NBClientPaginationPreviousLinkKey = @"prev";

#if DEBUG
static NBLogLevel LogLevel = NBLogLevelDebug;
#else
static NBLogLevel LogLevel = NBLogLevelWarning;
#endif

@interface NBPaginationInfo ()

- (void)updateFromDictionary:(NSDictionary *)dictionary;

@end

@implementation NBPaginationInfo

#pragma mark - Initializers

- (instancetype)initWithDictionary:(NSDictionary *)dictionary legacy:(BOOL)legacy
{
    self = [self init];
    if (self) {
        self.legacy = legacy;
        [self updateFromDictionary:dictionary];
    }
    return self;
}

#pragma mark - NBLogging

+ (void)updateLoggingToLevel:(NBLogLevel)logLevel
{
    LogLevel = logLevel;
}

#pragma mark - Public

- (void)updateCurrentPageNumber
{
    if (self.isLegacy) { return; }
    switch (self.currentDirection) {
        case NBPaginationDirectionNext:
            self.currentPageNumber += 1;
            break;
        case NBPaginationDirectionPrevious:
            self.currentPageNumber -= 1;
            break;
        default:
            NBLogWarning(@"Unsupported pagination direction, %d", self.currentDirection);
            break;
    }
}

#pragma mark Accessors

- (void)setCurrentPageNumber:(NSUInteger)currentPageNumber
{
    currentPageNumber = MAX(currentPageNumber, (NSUInteger)1);
    _currentPageNumber = currentPageNumber;
}

- (BOOL)isLastPage
{
    return (self.isLegacy ?
            self.currentPageNumber < self.numberOfTotalPages :
            !self.nextPageURLString);
}

- (NSUInteger)indexOfFirstItemAtPage:(NSUInteger)pageNumber
{
    return self.numberOfItemsPerPage * (pageNumber - 1);
}

- (NSUInteger)numberOfItemsAtPage:(NSUInteger)pageNumber
{
    NSUInteger number = self.numberOfItemsPerPage;
    if (pageNumber == self.currentPageNumber) {
        NSUInteger remainder = self.numberOfTotalAvailableItems % self.numberOfItemsPerPage;
        if (remainder) {
            number = remainder;
        }
    }
    return number;
}

- (NSDictionary *)queryParameters
{
    NSDictionary *parameters;
    NSMutableDictionary *mutableParameters = [[self dictionary] mutableCopy];
    if (self.isLegacy) {
        [mutableParameters removeObjectsForKeys:@[ NBClientNumberOfTotalPagesKey, NBClientNumberOfTotalItemsKey ]];
        parameters = [NSDictionary dictionaryWithDictionary:mutableParameters];
    } else {
        NSDictionary *dictionary = [self dictionary];
        NSURLComponents *components;
        if (self.currentDirection == NBPaginationDirectionNext && dictionary[NBClientPaginationNextLinkKey]) {
            components = [NSURLComponents componentsWithString:dictionary[NBClientPaginationNextLinkKey]];
        } else if (self.currentDirection == NBPaginationDirectionPrevious && dictionary[NBClientPaginationPreviousLinkKey]) {
            components = [NSURLComponents componentsWithString:dictionary[NBClientPaginationPreviousLinkKey]];
        }
        // Get parameters from generated URL strings, or get first page with initial parameters.
        if (components) {
            parameters = [components.query nb_queryStringParametersWithEncoding:NSUTF8StringEncoding];
        } else {
            [mutableParameters removeObjectsForKeys:@[ NBClientPaginationNextLinkKey, NBClientPaginationPreviousLinkKey ]];
            parameters = [NSDictionary dictionaryWithDictionary:mutableParameters];
        }
    }
    return parameters;
}

#pragma mark - NBDictionarySerializing

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.currentPageNumber = 0;
        self.numberOfTotalPages = 0;
        self.numberOfItemsPerPage = 10;
        self.numberOfTotalItems = 0;
        self.currentDirection = NBPaginationDirectionNext;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [self init];
    if (self) {
        [self updateFromDictionary:dictionary];
    }
    return self;
}

- (NSDictionary *)dictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    if (self.isLegacy) {
        dictionary[NBClientCurrentPageNumberKey] = @(self.currentPageNumber);
        dictionary[NBClientNumberOfTotalPagesKey] = @(self.numberOfTotalPages);
        dictionary[NBClientNumberOfItemsPerPageKey] = @(self.numberOfItemsPerPage);
        dictionary[NBClientNumberOfTotalItemsKey] = @(self.numberOfTotalItems);
    } else {
        dictionary[NBClientPaginationLimitKey] = @(self.numberOfItemsPerPage);
        if (self.nextPageURLString) {
            dictionary[NBClientPaginationNextLinkKey] = self.nextPageURLString;
        }
        if (self.previousPageURLString) {
            dictionary[NBClientPaginationPreviousLinkKey] = self.previousPageURLString;
        }
    }
    return dictionary;
}

- (BOOL)isEqualToDictionary:(NSDictionary *)dictionary
{
    if (self.isLegacy) {
        return ([dictionary[NBClientCurrentPageNumberKey] isEqual:@(self.currentPageNumber)] &&
                [dictionary[NBClientNumberOfTotalPagesKey] isEqual:@(self.numberOfTotalPages)] &&
                [dictionary[NBClientNumberOfItemsPerPageKey] isEqual:@(self.numberOfItemsPerPage)] &&
                [dictionary[NBClientNumberOfTotalItemsKey] isEqual:@(self.numberOfTotalItems)]);
    } else {
        return ([dictionary[NBClientPaginationLimitKey] isEqual:@(self.numberOfItemsPerPage)] &&
                [dictionary[NBClientPaginationNextLinkKey] isEqualToString:self.nextPageURLString] &&
                [dictionary[NBClientPaginationPreviousLinkKey] isEqualToString:self.previousPageURLString]);
    }
}

#pragma mark - Private

- (void)updateFromDictionary:(NSDictionary *)dictionary
{
    if (!dictionary) { return; }
    if (self.isLegacy) {
        self.currentPageNumber = [dictionary[NBClientCurrentPageNumberKey] unsignedIntegerValue];
        self.numberOfTotalPages = [dictionary[NBClientNumberOfTotalPagesKey] unsignedIntegerValue];
        self.numberOfItemsPerPage = [dictionary[NBClientNumberOfItemsPerPageKey] unsignedIntegerValue];
        self.numberOfTotalItems = [dictionary[NBClientNumberOfTotalItemsKey] unsignedIntegerValue];
    } else {
        if (dictionary[NBClientPaginationLimitKey]) {
            self.numberOfItemsPerPage = [dictionary[NBClientPaginationLimitKey] unsignedIntegerValue];
        } else if (dictionary[NBClientPaginationNextLinkKey]) {
            NSURLComponents *components = [NSURLComponents componentsWithString:dictionary[NBClientPaginationNextLinkKey]];
            NSDictionary *queryParameters = [components.query nb_queryStringParametersWithEncoding:NSUTF8StringEncoding];
            if (queryParameters[@"limit"]) {
                self.numberOfItemsPerPage = (NSUInteger)[queryParameters[@"limit"] integerValue];
            }
        }
        self.nextPageURLString = dictionary[NBClientPaginationNextLinkKey];
        self.previousPageURLString = dictionary[NBClientPaginationPreviousLinkKey];
    }
}

@end
