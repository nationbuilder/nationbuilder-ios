//
//  NBPeopleViewDataSource.m
//  NBClientExample
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBPeopleViewDataSource.h"

#import <NBClient/NBClient+People.h>
#import <NBClient/NBPaginationInfo.h>

#import "NBPersonViewDataSource.h"

#if DEBUG
static NBLogLevel LogLevel = NBLogLevelDebug;
#else
static NBLogLevel LogLevel = NBLogLevelWarning;
#endif

@interface NBPeopleViewDataSource () <NBViewDataSourceDelegate>

@property (nonatomic, weak, readwrite) NBClient *client;

@property (nonatomic, readwrite) NSArray *people;
@property (nonatomic) NSMutableDictionary *mutablePersonDataSources;

@end

@implementation NBPeopleViewDataSource

@synthesize error = _error;
@synthesize paginationInfo = _paginationInfo;

@synthesize people = _people;
@synthesize mutablePersonDataSources = _mutablePersonDataSources;

- (instancetype)initWithClient:(NBClient *)client
{
    self = [super init];
    if (self) {
        self.client = client;
        self.paginationInfo = [[NBPaginationInfo alloc] init];
    }
    return self;
}

#pragma mark - Public

- (NSArray *)people
{
    if (_people) {
        return _people;
    }
    self.people = @[];
    return _people;
}

- (NSDictionary *)personDataSources
{
    return self.mutablePersonDataSources;
}

- (void)fetchAll
{
    [self.client fetchPeopleWithPaginationInfo:self.paginationInfo completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
        if (error) {
            self.error = [self.class parseClientError:error];
            return;
        }
        self.paginationInfo = paginationInfo;
        NSArray *people = [self.class parseClientResults:items];
        if (self.paginationInfo.currentPageNumber > 1) {
            self.people = [self.people arrayByAddingObjectsFromArray:people];
        } else {
            self.people = people;
        }
    }];
}

#pragma mark - NBCollectionViewDataSource

// Create child data sources.
- (id<NBViewDataSource>)dataSourceForItem:(NSDictionary *)item
{
    NBPersonViewDataSource *dataSource = [[NBPersonViewDataSource alloc] initWithClient:self.client];
    dataSource.delegate = self;
    dataSource.person = item;
    if (item && item[@"id"]) {
        self.mutablePersonDataSources[item[@"id"]] = dataSource;
    }
    return dataSource;
}
- (id<NBViewDataSource>)dataSourceForItemAtIndex:(NSUInteger)index
{
    NBPersonViewDataSource *dataSource;
    if (index >= self.people.count) {
        return nil;
    }
    NSDictionary *person = self.people[index];
    dataSource = self.mutablePersonDataSources[person[@"id"]];
    if (!dataSource) {
        dataSource = [self dataSourceForItem:person];
    }
    return dataSource;
}

#pragma mark - NBViewDataSourceDelegate

- (void)dataSource:(id<NBViewDataSource>)dataSource didChangeValueForKeyPath:(NSString *)keyPath
{
    if ([dataSource isKindOfClass:[NBPersonViewDataSource class]] && [keyPath isEqualToString:NSStringFromSelector(@selector(person))]) {
        NBPersonViewDataSource *personDataSource = dataSource;
        NSMutableArray *people = self.people.mutableCopy;
        NSDictionary *person = personDataSource.person;
        if (person) {
            // Keep `people` synced with `mutablePersonDataSources`.
            NSUInteger index = [self.people indexOfObjectPassingTest:^BOOL(NSDictionary *aPerson, NSUInteger idx, BOOL *stop) {
                return [aPerson[@"id"] isEqual:person[@"id"]];
            }];
            if (index == NSNotFound) {
                // Handle creates.
                [people insertObject:person atIndex:0];
                self.mutablePersonDataSources[person[@"id"]] = [self dataSourceForItem:person];
            } else {
                people[index] = person;
            }
            self.people = [NSArray arrayWithArray:people];
        } else {
            // Handle deletes.
            NSString *identifier = [self.personDataSources keysOfEntriesPassingTest:^BOOL(NSString *identifier, NBPersonViewDataSource *aDataSource, BOOL *stop) {
                return aDataSource == dataSource;
            }].allObjects.firstObject;
            // Remove data source and item.
            [self.mutablePersonDataSources removeObjectForKey:identifier];
            for (NSDictionary *person in self.people) {
                if ([person[@"id"] isEqual:identifier]) {
                    [people removeObject:person];
                }
            }
            self.people = [NSArray arrayWithArray:people];
        }
    }
}

#pragma mark - NBViewDataSource

+ (void)updateLoggingToLevel:(NBLogLevel)logLevel
{
    LogLevel = logLevel;
}

- (void)cleanUp:(NSError *__autoreleasing *)error
{
    self.paginationInfo = nil;
    self.people = nil;
    self.mutablePersonDataSources = nil;
}

+ (NSError *)parseClientError:(NSError *)error
{
    return [NBPersonViewDataSource parseClientError:error];
}

+ (id)parseClientResults:(id)results
{
    NSAssert([results isKindOfClass:[NSArray class]], @"Results should be an array.");
    NSMutableArray *items = [NSMutableArray array];
    for (NSDictionary *item in results) {
        [items addObject:[NBPersonViewDataSource parseClientResults:item]];
    }
    return [NSArray arrayWithArray:items];
}

#pragma mark - Private

- (void)setPeople:(NSArray *)people
{
    // Guard.
    NSAssert(!people.count || self.paginationInfo, @"Pagination info should be set before adding people.");
    // Will.
    if (self.paginationInfo) {
        self.paginationInfo.currentPageNumber = !people ? 1 : ceil((double)people.count / self.paginationInfo.numberOfItemsPerPage);
        self.paginationInfo.numberOfTotalAvailableItems = people.count;
    }
    // Set.
    _people = people;
}

- (NSMutableDictionary *)mutablePersonDataSources
{
    if (_mutablePersonDataSources) {
        return _mutablePersonDataSources;
    }
    _mutablePersonDataSources = [NSMutableDictionary dictionary];
    return _mutablePersonDataSources;
}

@end
