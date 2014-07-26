//
//  NBPersonDataSource.m
//  NBClientExample
//
//  Created by Peng Wang on 7/24/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBPersonDataSource.h"

#import <NBClient/NBClient+People.h>

static NSString *PersonKeyPath;
static NSString *TagDelimiter = @", ";

@interface NBPersonDataSource ()

@property (nonatomic, weak) NBClient *client;

@property (nonatomic, strong) NSURLSessionDataTask *saveTask;

@end

@implementation NBPersonDataSource

@synthesize error = _error;
@synthesize changes = _changes;
@synthesize parentDataSource = _parentDataSource;

- (instancetype)initWithClient:(NBClient *)client
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        PersonKeyPath = NSStringFromSelector(@selector(person));
    });
    self = [super init];
    if (self) {
        self.client = client;
        self.person = @{};
    }
    return self;
}

- (void)dealloc
{
    self.parentDataSource = nil;
}

#pragma mark - Public

- (BOOL)save
{
    BOOL willSave = NO;
    NSMutableDictionary *realChanges = [NSMutableDictionary dictionary];
    [self.changes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        id original = self.person[key];
        if (![obj isEqual:original]) {
            realChanges[key] = obj;
        }
    }];
    if (!realChanges.count) {
        NSLog(@"INFO: No changes detected. Aborting save.");
        return willSave;
    }
    willSave = YES;
    NSMutableDictionary *parsedChanges = [self.class parseChanges:realChanges];
    void (^completion)(NSDictionary *, NSError *) = ^(NSDictionary *item, NSError *error) {
        if (error) {
            self.error = [self.class parseClientError:error];
            return;
        }
        self.person = [self.class parseClientResults:item];
        self.saveTask = nil;
    };
    if (self.person[@"id"]) {
        self.saveTask = [self.client savePersonByIdentifier:[self.person[@"id"] unsignedIntegerValue]
                                             withParameters:parsedChanges
                                          completionHandler:completion];
    } else {
        self.saveTask = [self.client createPersonWithParameters:parsedChanges
                                              completionHandler:completion];
    }
    return willSave;
}

- (void)cancelSave
{
    if (!self.saveTask) {
        return;
    }
    [self.saveTask cancel];
}

#pragma mark - NBDataSource

- (void)cleanUp:(NSError *__autoreleasing *)error
{
    self.person = nil;
    self.profileImage = nil;
}

- (id)changes
{
    if (_changes) {
        return _changes;
    }
    _changes = [NSMutableDictionary dictionary];
    return _changes;
}

- (void)setChanges:(id)changes
{
    NSAssert([_changes isKindOfClass:[NSMutableDictionary class]], @"Invalid argument for changes dictionary.");
    static NSString *key;
    key = key ?: NSStringFromSelector(@selector(changes));
    [self willChangeValueForKey:key];
    _changes = changes;
    [self didChangeValueForKey:key];
}

- (void)setParentDataSource:(id<NBDataSource>)parentDataSource
{
    if (self.parentDataSource) {
        [self removeObserver:self.parentDataSource forKeyPath:PersonKeyPath];
    }
    // Boilerplate.
    static NSString *key;
    key = key ?: NSStringFromSelector(@selector(parentDataSource));
    [self willChangeValueForKey:key];
    _parentDataSource = parentDataSource;
    [self didChangeValueForKey:key];
    // END: Boilerplate.
    if (self.parentDataSource) {
        [self addObserver:self.parentDataSource forKeyPath:PersonKeyPath options:0 context:NULL];
    }
}

+ (id)parseChanges:(id)changes
{
    NSAssert([changes isKindOfClass:[NSMutableDictionary class]], @"Invalid argument for changes dictionary.");
    NSMutableDictionary *results = [changes mutableCopy]; // Don't directly modify `changes`.
    if (results[@"full_name"]) {
        // NOTE: API should allow just updating `full_name`.
        NSString *fullName = results[@"full_name"];
        NSRange range = [fullName rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
                                                  options:NSBackwardsSearch];
        if (range.location > fullName.length) {
            range.location = fullName.length;
        }
        results[@"first_name"] = [fullName substringToIndex:range.location];
        results[@"last_name"] = @"";
        if (range.location < fullName.length) {
            results[@"last_name"] = [fullName substringFromIndex:(range.location + 1)];
        }
        [results removeObjectForKey:@"full_name"];
    }
    if (results[@"tags_text"]) {
        NSArray *tags = [results[@"tags_text"] componentsSeparatedByString:TagDelimiter];
        NSMutableArray *cleanTags = [NSMutableArray array];
        [tags enumerateObjectsUsingBlock:^(NSString *tag, NSUInteger idx, BOOL *stop) {
            [cleanTags addObject:[tag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }];
        [results removeObjectForKey:@"tags_text"];
        results[@"tags"] = cleanTags;
    }
    return results;
}

+ (NSError *)parseClientError:(NSError *)error
{
    NSMutableDictionary *userInfo = error.userInfo.mutableCopy;
    NSString *title = userInfo[NBClientErrorMessageKey];
    if (!title.length) {
        title = NSLocalizedString(@"title.error", nil);
    }
    NSString *message = userInfo[NSLocalizedFailureReasonErrorKey];
    BOOL isValidationError = [userInfo[NBClientErrorCodeKey] isEqualToString:@"validation_failed"];
    if (isValidationError) {
        message = [userInfo[NBClientErrorValidationErrorsKey] componentsJoinedByString:@", "];
    }
    if (title) {
        userInfo[NBUIErrorTitleKey] = title;
    }
    if (message) {
        userInfo[NBUIErrorMessageKey] = message;
    }
    return [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
}

+ (id)parseClientResults:(id)results
{
    NSAssert([results isKindOfClass:[NSDictionary class]], @"Results should be a dictionary.");
    NSMutableDictionary *item = [results mutableCopy];
    for (NSString *key in [results allKeys]) {
        id value = results[key];
        if (value == [NSNull null]) {
            item[key] = @"";
        }
    }
    // Defaults.
    if (![item[@"first_name"] length]) {
        item[@"first_name"] = NSLocalizedString(@"person.name-unknown", nil);
    }
    // Additions.
    if (!item[@"full_name"]) {
        NSString *fullName = [NSString localizedStringWithFormat:NSLocalizedString(@"person.full-name.format", nil),
                              item[@"first_name"], item[@"last_name"]];
        fullName = [fullName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        item[@"full_name"] = fullName;
    }
    NSArray *tags = item[@"tags"];
    item[@"tags_text"] = [tags componentsJoinedByString:TagDelimiter];
    // END: Additions.
    return [NSDictionary dictionaryWithDictionary:item];
}

@end
