//
//  NBPeopleViewController.m
//  NBClientExample
//
//  Created by Peng Wang on 7/22/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBPeopleViewController.h"

#import <NBClient/NBPaginationInfo.h>

#import "NBPeopleDataSource.h"
#import "NBPeopleViewFlowLayout.h"
#import "NBPersonCellView.h"
#import "NBPersonDataSource.h"
#import "NBPersonViewController.h"

static NSString *CellReuseIdentifier = @"PersonCell";
static NSString *SectionHeaderReuseIdentifier = @"PeopleSectionHeader";
static NSString *SectionFooterReuseIdentifier = @"PeopleSectionFooter";

static NSUInteger SectionHeaderPaginationPageLabelTag = 1;
static NSUInteger SectionHeaderPaginationItemLabelTag = 2;

static NSString *ShowPersonSegueIdentifier = @"ShowPersonSegue";

static NSDictionary *DefaultNibNames;

static NSString *PeopleKeyPath;
static NSString *ContentOffsetKeyPath;
static void *observationContext = &observationContext;

@interface NBPeopleViewController ()

<UICollectionViewDelegateFlowLayout, NBCollectionViewCellDelegate>

@property (nonatomic, strong, readwrite) NSMutableDictionary *nibNames;

@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@property (nonatomic, strong) UIBarButtonItem *createButtonItem;
@property (nonatomic, strong) UIBarButtonItem *deleteButtonItem;

@property (nonatomic) NSUInteger numberToDelete;
@property (nonatomic, readonly, getter = isDeleting) BOOL deleting;

@property (nonatomic) NBScrollViewPullActionState refreshState;
@property (nonatomic) NBScrollViewPullActionState loadMoreState;

- (IBAction)presentPersonView:(id)sender;

- (void)setUpCreating;
- (IBAction)startCreating:(id)sender;

- (void)setUpDeleting;
- (IBAction)toggleDeleting:(id)sender;
- (IBAction)deleteHighlighted:(id)sender;
- (IBAction)clearNeedsDeletes:(id)sender;

- (void)setUpPagination;
- (void)completePaginationSetup;
- (void)tearDownPagination;

- (IBAction)presentErrorView:(id)sender;

- (NBPersonCellView *)previousCellForCell:(NBPersonCellView *)cell;

@end

@implementation NBPeopleViewController

@synthesize dataSource = _dataSource;
@synthesize busy = _busy;
@synthesize busyIndicator = _busyIndicator;
@synthesize cancelButtonItem = _cancelButtonItem;

- (instancetype)initWithNibNames:(NSDictionary *)nibNamesOrNil
                          bundle:(NSBundle *)nibBundleOrNil
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        DefaultNibNames = @{ NBNibNameViewKey: NSStringFromClass([self class]),
                             NBNibNameCellViewKey: NSStringFromClass([NBPersonCellView class]),
                             NBNibNameSectionHeaderViewKey: @"NBPeoplePageHeaderView",
                             NBNibNameDecorationViewKey: @"NBPeopleDecorationLabel" };
        PeopleKeyPath = NSStringFromSelector(@selector(people));
        ContentOffsetKeyPath = NSStringFromSelector(@selector(contentOffset));
    });
    // Boilerplate.
    self.nibNames = DefaultNibNames.mutableCopy;
    [self.nibNames addEntriesFromDictionary:nibNamesOrNil];
    // END: Boilerplate.
    self = [self initWithNibName:self.nibNames[NBNibNameViewKey] bundle:nibBundleOrNil];
    return self;
}

- (void)dealloc
{
    [self.dataSource cleanUp:NULL];
    self.dataSource = nil;
    [self tearDownPagination];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self.dataSource cleanUp:NULL];
    [(id)self.dataSource fetchAll];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Boilerplate.
    [self.collectionView registerClass:[NBPersonCellView class] forCellWithReuseIdentifier:CellReuseIdentifier];
    if (self.nibNames) {
        [self.collectionView registerNib:[UINib nibWithNibName:self.nibNames[NBNibNameCellViewKey] bundle:self.nibBundle]
              forCellWithReuseIdentifier:CellReuseIdentifier];
        if (self.nibNames[NBNibNameSectionHeaderViewKey]) {
            [self.collectionView registerNib:[UINib nibWithNibName:self.nibNames[NBNibNameSectionHeaderViewKey] bundle:self.nibBundle]
                  forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                         withReuseIdentifier:SectionHeaderReuseIdentifier];
        }
        // NOTE: No footer by default.
        if (self.nibNames[NBNibNameSectionFooterViewKey]) {
            [self.collectionView registerNib:[UINib nibWithNibName:self.nibNames[NBNibNameSectionFooterViewKey] bundle:self.nibBundle]
                  forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                         withReuseIdentifier:SectionFooterReuseIdentifier];
        }
        if (self.nibNames[NBNibNameDecorationViewKey]) {
            NBPeopleViewFlowLayout *layout = (id)self.collectionViewLayout;
            for (Class aClass in layout.decorationViewClasses) {
                NSString *kind = NSStringFromClass(aClass);
                [self.collectionViewLayout registerClass:aClass forDecorationViewOfKind:kind];
            }
        }
    }
    // END: Boilerplate.
    [self setUpCreating];
    [self setUpPagination];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // Try (re)fetching if list is empty.
    NBPeopleDataSource *dataSource = (id)self.dataSource;
    if (!dataSource.people.count) {
        self.busy = YES;
        [(id)self.dataSource fetchAll];
    }
}
- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    // Manually deselect on successful navigation.
    if (self.selectedIndexPath) {
        [self.collectionView deselectItemAtIndexPath:self.selectedIndexPath animated:NO];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self completePaginationSetup];
    });
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    NBPeopleViewFlowLayout *layout = (id)self.collectionViewLayout;
    layout.originalContentInset = self.collectionView.contentInset;
}

- (void)performSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqual:ShowPersonSegueIdentifier]) {
        [self presentPersonView:sender];
    } else {
        [super performSegueWithIdentifier:identifier sender:sender];
    }
}

#pragma mark - NBViewController

- (void)setDataSource:(id<NBDataSource>)dataSource
{
    // Tear down.
    if (self.dataSource) {
        [(id)self.dataSource removeObserver:self forKeyPath:PeopleKeyPath context:&observationContext];
        [(id)self.dataSource removeObserver:self forKeyPath:NBDataSourceErrorKeyPath context:&observationContext];
    }
    // Boilerplate.
    static NSString *key;
    key = key ?: NSStringFromSelector(@selector(dataSource));
    [self willChangeValueForKey:key];
    _dataSource = dataSource;
    [self didChangeValueForKey:key];
    // END: Boilerplate.
    // Set up.
    if (self.dataSource) {
        NSAssert([self.dataSource isKindOfClass:[NBPeopleDataSource class]], @"Data source must be of certain type.");
        [(id)self.dataSource addObserver:self forKeyPath:PeopleKeyPath options:0 context:&observationContext];
        [(id)self.dataSource addObserver:self forKeyPath:NBDataSourceErrorKeyPath options:0 context:&observationContext];
    }
}

#pragma mark Busy & Cancel

- (void)setBusy:(BOOL)busy
{
    if (busy == self.busy) {
        return;
    }
    // Boilerplate.
    static NSString *key;
    key = key ?: NSStringFromSelector(@selector(isBusy));
    [self willChangeValueForKey:key];
    _busy = busy;
    [self didChangeValueForKey:key];
    // END: Boilerplate.
    if (busy) {
        self.navigationItem.titleView = self.busyIndicator;
        [self.busyIndicator startAnimating];
    } else {
        self.navigationItem.titleView = nil;
        [self.busyIndicator stopAnimating];
    }
}

- (UIActivityIndicatorView *)busyIndicator
{
    if (_busyIndicator) {
        return _busyIndicator;
    }
    self.busyIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    return _busyIndicator;
}

- (UIBarButtonItem *)cancelButtonItem
{
    if (_cancelButtonItem) {
        return _cancelButtonItem;
    }
    self.cancelButtonItem = [[UIBarButtonItem alloc]
                             initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                             target:self action:@selector(cancelPendingAction:)];
    return _cancelButtonItem;
}

- (IBAction)cancelPendingAction:(id)sender
{
    if (self.isDeleting) {
        self.numberToDelete = 0;
    }
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != &observationContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if ([keyPath isEqual:PeopleKeyPath]) {
        // TODO: Incremental updates.
        NBPeopleDataSource *dataSource = (id)self.dataSource;
        if (!dataSource.people.count) {
            return;
        }
        if (self.isBusy) {
            // If we were busy refreshing data, now we're not.
            self.busy = NO;
            if (self.loadMoreState == NBScrollViewPullActionStateInProgress) {
                self.loadMoreState = NBScrollViewPullActionStateStopped;
            }
            if (self.refreshState == NBScrollViewPullActionStateInProgress) {
                self.refreshState = NBScrollViewPullActionStateStopped;
            }
        }
        [self.collectionView reloadData];
        if (self.isDeleting) {
            self.numberToDelete = 0;
        }
    } else if ([keyPath isEqual:NBDataSourceErrorKeyPath] && self.dataSource.error) {
        if (self.isBusy) { // If we were busy refreshing data, now we're not.
            self.busy = NO;
        }
        [self presentErrorView:self];
    } else if ([keyPath isEqual:ContentOffsetKeyPath]) {
        // Update on appending.
        [self scrollViewDidScroll:self.collectionView];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NBPeopleDataSource *dataSource = (id)self.dataSource;
    NSInteger number = dataSource.paginationInfo ? dataSource.paginationInfo.currentPageNumber : 1;
    return number;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NBPeopleDataSource *dataSource = (id)self.dataSource;
    NSInteger number = dataSource.paginationInfo ? [dataSource.paginationInfo numberOfItemsAtPage:(section + 1)] : 0;
    return number;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NBPersonCellView *cell = (id)[collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
    NBPeopleDataSource *dataSource = (id)self.dataSource;
    NSUInteger index = [dataSource.paginationInfo indexOfFirstItemAtPage:(indexPath.section + 1)] + indexPath.item;
    cell.dataSource = [(id)self.dataSource dataSourceForItemAtIndex:index]; // Automatically calls refreshData.
    cell.delegate = self;
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *view;
    if (kind == UICollectionElementKindSectionHeader) {
        view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:SectionHeaderReuseIdentifier forIndexPath:indexPath];
        NBPaginationInfo *paginationInfo = ((NBPeopleDataSource *)self.dataSource).paginationInfo;
        for (UIView *subview in view.subviews) {
            if (subview.tag == SectionHeaderPaginationPageLabelTag) {
                UILabel *pageLabel = (id)subview;
                pageLabel.text = [[NSString localizedStringWithFormat:NSLocalizedString(@"pagination.page-title.format", nil),
                                   (indexPath.section + 1), paginationInfo.numberOfTotalPages]
                                  uppercaseStringWithLocale:[NSLocale currentLocale]];
            } else if (subview.tag == SectionHeaderPaginationItemLabelTag) {
                UILabel *itemLabel = (id)subview;
                NSUInteger startItemIndex = [paginationInfo indexOfFirstItemAtPage:(indexPath.section + 1)];
                NSUInteger endItemNumber = startItemIndex + [self.collectionView numberOfItemsInSection:indexPath.section];
                itemLabel.text = [[NSString localizedStringWithFormat:NSLocalizedString(@"pagination.item-title.format", nil),
                                   (startItemIndex + 1), endItemNumber]
                                  uppercaseStringWithLocale:[NSLocale currentLocale]];
            }
        }
    }
    return view;
}

#pragma mark - NBCollectionViewCellDelegate

- (void)collectionViewCell:(UICollectionViewCell *)cell didSetHighlighted:(BOOL)highlighted
{
    NBPersonCellView *previousCell = [self previousCellForCell:(id)cell];
    if (previousCell) {
        previousCell.bottomBorderView.hidden = highlighted;
    }
}

- (void)collectionViewCell:(UICollectionViewCell *)cell didSetSelected:(BOOL)selected
{
    NBPersonCellView *previousCell = [self previousCellForCell:(id)cell];
    if (previousCell) {
        previousCell.bottomBorderView.hidden = selected;
    }
}

- (void)collectionViewCell:(UICollectionViewCell *)cell didSetNeedsDelete:(BOOL)needsDelete
{
    self.numberToDelete += needsDelete ? 1 : -1;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedIndexPath = indexPath;
    [self performSegueWithIdentifier:ShowPersonSegueIdentifier sender:self];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NBPeopleViewFlowLayout *layout = (id)self.collectionViewLayout;
    CGFloat offsetOverflow;
    CGFloat requiredOffsetOverflow = layout.requiredContentOffsetOverflow.floatValue;
    BOOL didPassThresold;
    if (self.loadMoreState != NBScrollViewPullActionStateInProgress) {
        // Update load-more state.
        offsetOverflow = layout.bottomOffsetOverflow;
        didPassThresold = offsetOverflow > requiredOffsetOverflow;
        BOOL didResizeFromAppending = offsetOverflow <= requiredOffsetOverflow;
        if (!scrollView.isDragging && offsetOverflow > 0.0f && self.loadMoreState == NBScrollViewPullActionStatePlanned) {
            self.loadMoreState = NBScrollViewPullActionStateInProgress;
        } else if (didPassThresold && scrollView.isDragging && offsetOverflow > 0.0f && self.loadMoreState == NBScrollViewPullActionStateStopped) {
            self.loadMoreState = NBScrollViewPullActionStatePlanned;
        } else if (didResizeFromAppending && self.loadMoreState != NBScrollViewPullActionStateStopped) {
            self.loadMoreState = NBScrollViewPullActionStateStopped;
        }
    }
    if (self.refreshState != NBScrollViewPullActionStateInProgress) {
        // Update refresh state.
        offsetOverflow = layout.topOffsetOverflow;
        didPassThresold = offsetOverflow > requiredOffsetOverflow;
        if (!scrollView.isDragging && offsetOverflow > 0.0f && self.refreshState == NBScrollViewPullActionStatePlanned) {
            self.refreshState = NBScrollViewPullActionStateInProgress;
        } else if (didPassThresold && scrollView.isDragging && offsetOverflow > 0.0f && self.refreshState == NBScrollViewPullActionStateStopped) {
            self.refreshState = NBScrollViewPullActionStatePlanned;
        }
    }
}

#pragma mark - Private

#pragma mark Fetching

- (void)setRefreshState:(NBScrollViewPullActionState)refreshState
{
    if (self.refreshState == refreshState) {
        return;
    }
    NBScrollViewPullActionState previousState = self.refreshState;
    // Boilerplate.
    static NSString *key;
    key = key ?: NSStringFromSelector(@selector(refreshState));
    [self willChangeValueForKey:key];
    _refreshState = refreshState;
    [self didChangeValueForKey:key];
    // END: Boilerplate.
    UIScrollView *scrollView = self.collectionView;
    NBPeopleDataSource *dataSource = (id)self.dataSource;
    NBPeopleViewFlowLayout *layout = (id)self.collectionViewLayout;
    UIEdgeInsets contentInset = scrollView.contentInset;
    switch (self.refreshState) {
        case NBScrollViewPullActionStateStopped:
            self.busy = NO;
            contentInset = layout.originalContentInset;
            break;
        case NBScrollViewPullActionStatePlanned:
            break;
        case NBScrollViewPullActionStateInProgress:
            // Update UI.
            self.busy = YES;
            contentInset = layout.originalContentInset;
            contentInset.top += layout.topOffsetOverflow;
            // Update data.
            NSError *error;
            [dataSource cleanUp:&error];
            [dataSource fetchAll];
            break;
    }
    if (self.refreshState == NBScrollViewPullActionStateStopped && previousState == NBScrollViewPullActionStateInProgress) {
        [UIView animateWithDuration:0.3f delay:0.0f
                            options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                         animations:^{ scrollView.contentInset = contentInset; }
                         completion:nil];
    } else {
        scrollView.contentInset = contentInset;
    }
}

- (IBAction)presentPersonView:(id)sender
{
    NBPersonViewController *viewController = [[NBPersonViewController alloc] initWithNibNames:nil bundle:nil];
    if (sender == self.createButtonItem) {
        // We're creating.
        viewController.modalPresentationStyle = UIModalPresentationPageSheet;
        viewController.dataSource = [(id)self.dataSource dataSourceForItem:nil];
        viewController.mode = NBPersonViewControllerModeCreate;
        // Boilerplate.
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
        navigationController.view.backgroundColor = [UIColor whiteColor];
        // END: Boilerplate.
        [self.navigationController presentViewController:navigationController animated:YES completion:nil];
    } else {
        viewController.mode = NBPersonViewControllerModeViewAndEdit;
        NBPaginationInfo *paginationInfo = ((NBPeopleDataSource *)self.dataSource).paginationInfo;
        NSUInteger startItemIndex = [paginationInfo indexOfFirstItemAtPage:(self.selectedIndexPath.section + 1)];
        viewController.dataSource = [(id)self.dataSource dataSourceForItemAtIndex:startItemIndex + self.selectedIndexPath.item];
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

#pragma mark Creating

- (UIBarButtonItem *)createButtonItem
{
    if (_createButtonItem) {
        return _createButtonItem;
    }
    self.createButtonItem = [[UIBarButtonItem alloc]
                             initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                             target:self action:@selector(startCreating:)];
    return _createButtonItem;
}

- (void)setUpCreating
{
    self.navigationItem.rightBarButtonItem = self.createButtonItem;
}

- (IBAction)startCreating:(id)sender
{
    [self performSegueWithIdentifier:ShowPersonSegueIdentifier sender:sender];
}

#pragma mark Deleting

- (UIBarButtonItem *)deleteButtonItem
{
    if (_deleteButtonItem) {
        return _deleteButtonItem;
    }
    self.deleteButtonItem = [[UIBarButtonItem alloc]
                             initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                             target:self action:@selector(deleteHighlighted:)];
    return _deleteButtonItem;
}

- (void)setNumberToDelete:(NSUInteger)numberToDelete
{
    BOOL shouldClear = numberToDelete == 0 && abs(numberToDelete - self.numberToDelete) > 0;
    if (shouldClear) {
        NSLog(@"INFO: Clearing %d pending deletes.", self.numberToDelete);
        [self clearNeedsDeletes:self];
    }
    // Boilerplate.
    static NSString *key;
    key = key ?: NSStringFromSelector(@selector(numberToDelete));
    [self willChangeValueForKey:key];
    _numberToDelete = numberToDelete;
    [self didChangeValueForKey:key];
    // END: Boilerplate.
    [self toggleDeleting:self];
}

- (BOOL)isDeleting
{
    return self.navigationItem.rightBarButtonItem == self.deleteButtonItem;
}

- (void)setUpDeleting
{
    _numberToDelete = 0;
}
    
- (IBAction)toggleDeleting:(id)sender
{
    UIBarButtonItem *buttonItem;
    UIBarButtonItem *cancelButtonItem;
    if (self.numberToDelete > 0) {
        buttonItem = self.deleteButtonItem;
        cancelButtonItem = self.cancelButtonItem;
    } else {
        _numberToDelete = 0;
        buttonItem = self.createButtonItem;
        cancelButtonItem = nil;
    }
    [self.navigationItem setRightBarButtonItem:buttonItem animated:YES];
    [self.navigationItem setLeftBarButtonItem:cancelButtonItem animated:YES];
}

- (IBAction)deleteHighlighted:(id)sender
{
    self.busy = YES;
    [(id)self.dataSource deleteAll];
}

- (IBAction)clearNeedsDeletes:(id)sender
{
    NBPeopleDataSource *dataSource = (id)self.dataSource;
    [dataSource.personDataSources enumerateKeysAndObjectsUsingBlock:^(NSNumber *identifier, NBPersonDataSource *personDataSource, BOOL *stop) {
        personDataSource.needsDelete = NO;
    }];
}

#pragma mark Pagination

- (void)setLoadMoreState:(NBScrollViewPullActionState)loadMoreState
{
    if (self.loadMoreState == loadMoreState) {
        return;
    }
    NBScrollViewPullActionState previousState = self.loadMoreState;
    // Boilerplate.
    static NSString *key;
    key = key ?: NSStringFromSelector(@selector(loadMoreState));
    [self willChangeValueForKey:key];
    _loadMoreState = loadMoreState;
    [self didChangeValueForKey:key];
    // END: Boilerplate.
    UIScrollView *scrollView = self.collectionView;
    NBPeopleDataSource *dataSource = (id)self.dataSource;
    NBPaginationInfo *paginationInfo = dataSource.paginationInfo;
    NBPeopleViewFlowLayout *layout = (id)self.collectionViewLayout;
    UIEdgeInsets contentInset = scrollView.contentInset;
    BOOL shouldHideIndicator = NO; // Since we're setting contentInset, the indicator can get wild.
    switch (self.loadMoreState) {
        case NBScrollViewPullActionStateStopped:
            self.busy = NO;
            contentInset = layout.originalContentInset;
            break;
        case NBScrollViewPullActionStatePlanned:
            break;
        case NBScrollViewPullActionStateInProgress:
            // Guard.
            if (paginationInfo.currentPageNumber == paginationInfo.numberOfTotalPages) {
                self.loadMoreState = NBScrollViewPullActionStateStopped;
                break;
            }
            // Update UI.
            self.busy = YES;
            contentInset = layout.originalContentInset;
            contentInset.bottom += layout.bottomOffsetOverflow;
            shouldHideIndicator = YES;
            // Update data.
            paginationInfo.currentPageNumber += 1;
            [dataSource fetchAll];
            break;
    }
    scrollView.contentInset = contentInset;
    if (self.loadMoreState == NBScrollViewPullActionStateStopped && previousState == NBScrollViewPullActionStateInProgress) {
        // Auto-scroll to new page.
        CGPoint contentOffset = scrollView.contentOffset;
        contentOffset.y += scrollView.bounds.size.height - scrollView.contentInset.top;
        [scrollView setContentOffset:contentOffset animated:YES];
        dispatch_async(dispatch_get_main_queue(), ^{ // Defer showing the indicator until offset animation finishes.
            scrollView.showsVerticalScrollIndicator = YES;
        });
    } else {
        scrollView.showsVerticalScrollIndicator = !shouldHideIndicator;
    }
}

- (void)setUpPagination
{
    [self.collectionView addObserver:self forKeyPath:ContentOffsetKeyPath options:0 context:&observationContext];
}
- (void)completePaginationSetup
{
    NBPeopleViewFlowLayout *layout = (id)self.collectionViewLayout;
    layout.originalContentInset = self.collectionView.contentInset;
}
- (void)tearDownPagination
{
    [self.collectionView removeObserver:self forKeyPath:ContentOffsetKeyPath context:&observationContext];
}

#pragma mark Error

- (IBAction)presentErrorView:(id)sender
{
    NSDictionary *error = self.dataSource.error.userInfo;
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:error[NBUIErrorTitleKey]
                                                        message:error[NBUIErrorMessageKey]
                                                       delegate:self cancelButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"title.ok", nil), nil];
    [alertView show];
}

#pragma mark Helpers

- (NBPersonCellView *)previousCellForCell:(UICollectionViewCell *)cell
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    if (indexPath.item == 0) {
        return nil;
    }
    return (id)[self.collectionView cellForItemAtIndexPath:
                [NSIndexPath indexPathForItem:indexPath.item - 1 inSection:indexPath.section]];
}

@end
