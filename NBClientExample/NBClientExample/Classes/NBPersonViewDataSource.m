//
//  NBPersonViewDataSource.m
//  NBClientExample
//
//  Copyright (c) 2014-2015 NationBuilder. All rights reserved.
//

#import "NBPersonViewDataSource.h"

#import <NBClient/NBClient+People.h>

static NSString *PersonKeyPath;
static NSString *TagDelimiter = @", ";

#if DEBUG
static NBLogLevel LogLevel = NBLogLevelDebug;
#else
static NBLogLevel LogLevel = NBLogLevelWarning;
#endif

@interface NBPersonViewDataSource ()

@property (nonatomic, weak) NBClient *client;

@property (nonatomic) NSURLSessionDataTask *saveTask;
@property (nonatomic) NSURLSessionDataTask *deleteTask;

@property (nonatomic, copy) NSDictionary *realChanges;

@end

@implementation NBPersonViewDataSource

@synthesize error = _error;
@synthesize delegate = _delegate;
@synthesize changes = _changes;

+ (void)initialize
{
    if (self == [NBPersonViewDataSource self]) {
        PersonKeyPath = NSStringFromSelector(@selector(person));
    }
}

- (instancetype)initWithClient:(NBClient *)client
{
    self = [super init];
    if (self) {
        self.client = client;
        self.person = @{};
    }
    return self;
}

#pragma mark - Public

- (BOOL)save
{
    BOOL willSave = NO;
    // Guard.
    NSDictionary *realChanges = [self realChanges];
    if (!realChanges.count) {
        NBLogInfo(@"No changes detected. Aborting save.");
        return willSave;
    }
    // Save.
    willSave = YES;
    NSMutableDictionary *parsedChanges = [self.class parseChanges:realChanges];
    void (^completion)(NSDictionary *, NSError *) = ^(NSDictionary *item, NSError *error) {
        // Handle client error.
        if (error) {
            self.error = [self.class parseClientError:error];
            return;
        }
        // Update and notify.
        self.person = [self.class parseClientResults:item];
        if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:didChangeValueForKeyPath:)]) {
            [self.delegate dataSource:self didChangeValueForKeyPath:NSStringFromSelector(@selector(person))];
        }
        // Teardown canceling.
        self.saveTask = nil;
    };
    if (self.person[@"id"]) {
        // Update existing.
        self.saveTask = [self.client savePersonByIdentifier:[self.person[@"id"] unsignedIntegerValue]
                                             withParameters:parsedChanges
                                          completionHandler:completion];
    } else {
        // Create new.
        self.saveTask = [self.client createPersonWithParameters:parsedChanges
                                              completionHandler:completion];
    }
    return willSave;
}
- (void)cancelSave
{
    if (!self.saveTask) { return; }
    [self.saveTask cancel];
}

- (BOOL)nb_delete
{
    BOOL willDelete = YES;
    self.deleteTask =
    [self.client
     deletePersonByIdentifier:[self.person[@"id"] unsignedIntegerValue]
     withCompletionHandler:^(NSDictionary *item, NSError *error) {
         // Handle client error.
         if (error) {
             self.error = [self.class parseClientError:error];
             return;
         }
         // Update and notify.
         [self cleanUp:&error];
         if (error) {
             self.error = error;
             return;
         }
         if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:didChangeValueForKeyPath:)]) {
             [self.delegate dataSource:self didChangeValueForKeyPath:NSStringFromSelector(@selector(person))];
         }
         // Teardown canceling.
         self.deleteTask = nil;
     }];
    return willDelete;
}
- (void)cancelDelete
{
    if (!self.deleteTask) { return; }
    [self.deleteTask cancel];
}

#pragma mark - Private

- (NSDictionary *)realChanges
{
    NSMutableDictionary *realChanges = [NSMutableDictionary dictionary];
    [self.changes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        id original = self.person[key];
        if (![obj isEqual:original]) {
            realChanges[key] = obj;
        }
    }];
    return realChanges;
}

#pragma mark - NBViewDataSource

+ (void)updateLoggingToLevel:(NBLogLevel)logLevel
{
    LogLevel = logLevel;
}

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
    // Guard.
    NSAssert([_changes isKindOfClass:[NSMutableDictionary class]], @"Invalid argument for changes dictionary.");
    // Set.
    _changes = changes;
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
    NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
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
