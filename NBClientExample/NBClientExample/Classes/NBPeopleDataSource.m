//
//  NBPeopleDataSource.m
//  NBClientExample
//
//  Created by Peng Wang on 7/23/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBPeopleDataSource.h"

#import <NBClient/NBClient+People.h>
#import <NBClient/NBPaginationInfo.h>

#import "NBPersonDataSource.h"

static NSString *PersonKeyPath;
static void *observationContext = &observationContext;

@interface NBPeopleDataSource ()

@property (nonatomic, weak, readwrite) NBClient *client;

@property (nonatomic, strong, readwrite) NSArray *people;
@property (nonatomic, strong) NSMutableDictionary *mutablePersonDataSources;

@end

@implementation NBPeopleDataSource

@synthesize error = _error;
@synthesize paginationInfo = _paginationInfo;

@synthesize people = _people;
@synthesize mutablePersonDataSources = _mutablePersonDataSources;

- (instancetype)initWithClient:(NBClient *)client
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        PersonKeyPath = NSStringFromSelector(@selector(person));
    });
    self = [super init];
    if (self) {
        self.client = client;
    }
    return self;
}

- (void)dealloc
{
    self.mutablePersonDataSources = nil;
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

- (void)deleteAll
{
    [self.mutablePersonDataSources enumerateKeysAndObjectsUsingBlock:^(NSNumber *identifier, NBPersonDataSource *dataSource, BOOL *stop) {
        if (dataSource.needsDelete) {
            [self.client
             deletePersonByIdentifier:identifier.unsignedIntegerValue
             withCompletionHandler:^(NSDictionary *item, NSError *error) {
                 dataSource.person = nil;
             }];
        }
    }];
}

#pragma mark - NBCollectionDataSource

// Create child data sources.
- (id<NBDataSource>)dataSourceForItem:(NSDictionary *)item
{
    NBPersonDataSource *dataSource = [[NBPersonDataSource alloc] initWithClient:self.client];
    dataSource.person = item;
    dataSource.parentDataSource = self;
    if (item && item[@"id"]) {
        self.mutablePersonDataSources[item[@"id"]] = dataSource;
    }
    return dataSource;
}
- (id<NBDataSource>)dataSourceForItemAtIndex:(NSUInteger)index
{
    NBPersonDataSource *dataSource;
    if (index >= self.people.count) {
        NSAssert(self.paginationInfo.numberOfTotalItems > self.people.count, @"Index should not be this big.");
        return nil;
    }
    NSDictionary *person = self.people[index];
    dataSource = self.mutablePersonDataSources[person[@"id"]];
    if (!dataSource) {
        dataSource = [self dataSourceForItem:person];
    }
    return dataSource;
}

#pragma mark - NBDataSource

- (void)cleanUp:(NSError *__autoreleasing *)error
{
    if (self.paginationInfo) {
        self.paginationInfo.currentPageNumber = 1;
    }
    self.people = [NSArray array];
    self.mutablePersonDataSources = nil;
}

+ (NSError *)parseClientError:(NSError *)error
{
    return [NBPersonDataSource parseClientError:error];
}

+ (id)parseClientResults:(id)results
{
    NSAssert([results isKindOfClass:[NSArray class]], @"Results should be an array.");
    NSMutableArray *items = [NSMutableArray array];
    for (NSDictionary *item in results) {
        [items addObject:[NBPersonDataSource parseClientResults:item]];
    }
    return [NSArray arrayWithArray:items];
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == NULL && [keyPath isEqual:PersonKeyPath]) {
        NBPersonDataSource *dataSource = object;
        NSMutableArray *people = self.people.mutableCopy;
        NSDictionary *person = dataSource.person;
        if (dataSource.person) {
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
            NSString *identifier = [self.personDataSources keysOfEntriesPassingTest:^BOOL(NSString *identifier, NBPersonDataSource *aDataSource, BOOL *stop) {
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
    } else if (context != &observationContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Private

- (void)setPeople:(NSArray *)people
{
    NSAssert(!people.count || self.paginationInfo, @"Pagination info should be set before adding people.");
    if (self.paginationInfo) {
        self.paginationInfo.currentPageNumber = !people ? 1 : ceil((double)people.count / self.paginationInfo.numberOfItemsPerPage);
        self.paginationInfo.numberOfTotalAvailableItems = people.count;
    }
    // Boilerplate.
    static NSString *key;
    key = key ?: NSStringFromSelector(@selector(people));
    [self willChangeValueForKey:key];
    _people = people;
    [self didChangeValueForKey:key];
    // END: Boilerplate.
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
