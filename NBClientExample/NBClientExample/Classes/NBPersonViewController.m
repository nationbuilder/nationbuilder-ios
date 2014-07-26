//
//  NBPersonViewController.m
//  NBClientExample
//
//  Created by Peng Wang on 7/24/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBPersonViewController.h"

#import "NBPersonDataSource.h"

static NSDictionary *DefaultNibNames;

@interface NBPersonViewController ()

@property (nonatomic, strong, readwrite) NSMutableDictionary *nibNames;

@end

@implementation NBPersonViewController

@synthesize dataSource = _dataSource;

- (instancetype)initWithNibNames:(NSDictionary *)nibNamesOrNil
                          bundle:(NSBundle *)nibBundleOrNil
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        DefaultNibNames = @{ NBNibNameViewKey: NSStringFromClass([self class]) };
    });
    // Boilerplate.
    self.nibNames = DefaultNibNames.mutableCopy;
    [self.nibNames addEntriesFromDictionary:nibNamesOrNil];
    // END: Boilerplate.
    self = [self initWithNibName:self.nibNames[NBNibNameViewKey] bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NBPersonDataSource *dataSource = self.dataSource;
    self.title = ([dataSource.person[@"first_name"] length] ? dataSource.person[@"first_name"] :
                  NSLocalizedString(@"person.name-unknown", nil));
}

@end
