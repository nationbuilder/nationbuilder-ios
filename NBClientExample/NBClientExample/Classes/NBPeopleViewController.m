//
//  NBPeopleViewController.m
//  NBClientExample
//
//  Created by Peng Wang on 7/22/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBPeopleViewController.h"

#import <NBClient/NBPaginationInfo.h>

#import <NBClient/UI/NBAccountButton.h>
#import <NBClient/UI/UIKitAdditions.h>

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

<UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate, NBCollectionViewCellDelegate>

@property (nonatomic, strong, readwrite) NSMutableDictionary *nibNames;

@property (nonatomic, strong, readwrite) UILabel *notReadyLabel;

@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@property (nonatomic, strong) UIBarButtonItem *createButtonItem;
@property (nonatomic, strong) UIBarButtonItem *deleteButtonItem;

@property (nonatomic) NSUInteger numberToDelete;
@property (nonatomic, getter = isDeleting) BOOL deleting;

@property (nonatomic) NBScrollViewPullActionState refreshState;
@property (nonatomic) NBScrollViewPullActionState loadMoreState;

- (void)fetchIfNeeded;
- (IBAction)presentPersonView:(id)sender;

- (void)setUpCreating;
- (IBAction)startCreating:(id)sender;

- (void)setUpDeleting;
- (IBAction)updateDeleting:(id)sender;
- (IBAction)deleteHighlighted:(id)sender;
- (IBAction)clearNeedsDeletes:(id)sender;

- (void)setUpPagination;
- (void)completePaginationSetup;
- (void)tearDownPagination;

- (IBAction)presentErrorView:(id)sender;

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
    self.ready = NO;
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
    if (self.navigationController) {
        self.navigationController.delegate = self;
    }
    if (!self.isReady) {
        self.collectionView.backgroundView = [[UIView alloc] initWithFrame:self.collectionView.bounds];
        [self.collectionView.backgroundView addSubview:self.notReadyLabel];
        [self.notReadyLabel sizeToFit];
        self.notReadyLabel.center = self.collectionView.backgroundView.center;
    }
    [self setUpCreating];
    [self setUpDeleting];
    [self setUpPagination];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // Try (re)fetching if list is empty.
    if (self.isReady && !self.isBusy) {
        [self fetchIfNeeded];
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
    // Set.
    _dataSource = dataSource;
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
    // Guard.
    if (busy == _busy) { return; }
    // Set.
    _busy = busy;
    // Did.
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
        self.deleting = NO;
        [self updateDeleting:sender];
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
            self.deleting = NO;
            [self updateDeleting:self];
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
    NSInteger number = dataSource.paginationInfo ? dataSource.paginationInfo.currentPageNumber : 0;
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
    [cell setDeleteSwitchVisible:self.isDeleting animated:NO];
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
    NBPersonCellView *previousCell = (id)[(id)self.collectionViewLayout previousVerticalCellForCell:cell];
    if (previousCell) {
        previousCell.bottomBorderView.hidden = highlighted;
    }
}

- (void)collectionViewCell:(UICollectionViewCell *)cell didSetSelected:(BOOL)selected
{
    NBPersonCellView *previousCell = (id)[(id)self.collectionViewLayout previousVerticalCellForCell:cell];
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
    NBPaginationInfo *paginationInfo = ((NBPeopleDataSource *)self.dataSource).paginationInfo;
    BOOL canLoadMore = paginationInfo.currentPageNumber < paginationInfo.numberOfTotalPages;
    layout.shouldShowLoadMore = canLoadMore;
    if (canLoadMore && self.loadMoreState != NBScrollViewPullActionStateInProgress) {
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

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    // Manually deselect on successful navigation.
    if (!self.selectedIndexPath) {
        return;
    }
    if (viewController.navigationController.modalPresentationStyle == UIModalPresentationFormSheet) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.collectionView deselectItemAtIndexPath:self.selectedIndexPath animated:NO];
        });
    } else if (viewController == self) {
        [self.collectionView deselectItemAtIndexPath:self.selectedIndexPath animated:NO];
    }
}

#pragma mark - Public

- (void)setReady:(BOOL)ready
{
    _ready = ready;
    // Did.
    self.createButtonItem.enabled = self.isReady;
    self.notReadyLabel.hidden = self.isReady;
    if (self.isReady) {
        [self fetchIfNeeded];
    }
}

- (UILabel *)notReadyLabel
{
    if (_notReadyLabel) {
        return _notReadyLabel;
    }
    self.notReadyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.notReadyLabel.text = NSLocalizedString(@"message.sign-in", nil);
    [self.notReadyLabel sizeToFit];
    if (!self.collectionView.backgroundView) {
        self.collectionView.backgroundView = [[UIView alloc] initWithFrame:self.collectionView.bounds];
    }
    [self.collectionView.backgroundView addSubview:self.notReadyLabel];
    [self.notReadyLabel nb_addCenterXConstraintToSuperview];
    [self.notReadyLabel nb_addCenterYConstraintToSuperview];
    return _notReadyLabel;
}

- (void)showAccountButton:(NBAccountButton *)accountButton
{
    // In situations where there isn't a lot of space:
    
    // 1. You can just show icons that update depending on the data source.
    
    accountButton.buttonType = NBAccountButtonTypeIconOnly;
    
    // 2. You can just show the name text, which will fall back to sign-in text.
    /*
    accountButton.buttonType = NBAccountButtonTypeNameOnly;
    */
    // 3. You can only show the avatar, which will fall back to icons. Hip
    //    circular icons are supported too.
    /*
    accountButton.buttonType = NBAccountButtonTypeAvatarOnly;
    accountButton.shouldUseCircleAvatarFrame = YES;
    */
    
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView:accountButton];
    [self.navigationItem setLeftBarButtonItem:buttonItem animated:YES];
}

#pragma mark - Private

#pragma mark Fetching

- (void)setRefreshState:(NBScrollViewPullActionState)refreshState
{
    // Guard.
    if (refreshState == _refreshState) { return; }
    // Will.
    NBScrollViewPullActionState previousState = self.refreshState;
    // Set.
    _refreshState = refreshState;
    // Did.
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

- (void)fetchIfNeeded
{
    NBPeopleDataSource *dataSource = (id)self.dataSource;
    if (!dataSource.people.count) {
        self.busy = YES;
        [(id)self.dataSource fetchAll];
    }
}

- (IBAction)presentPersonView:(id)sender
{
    NBPersonViewController *viewController = [[NBPersonViewController alloc] initWithNibNames:nil bundle:nil];
    NBPeopleViewFlowLayout *layout = (id)self.collectionViewLayout;
    BOOL shouldPresentAsModal = layout.hasMultipleColumns;
    if (sender == self.createButtonItem) {
        // We're creating.
        shouldPresentAsModal = YES;
        viewController.dataSource = [(id)self.dataSource dataSourceForItem:nil];
        viewController.mode = NBPersonViewControllerModeCreate;
    } else {
        // We're editing.
        viewController.mode = NBPersonViewControllerModeViewAndEdit;
        NBPaginationInfo *paginationInfo = ((NBPeopleDataSource *)self.dataSource).paginationInfo;
        NSUInteger startItemIndex = [paginationInfo indexOfFirstItemAtPage:(self.selectedIndexPath.section + 1)];
        viewController.dataSource = [(id)self.dataSource dataSourceForItemAtIndex:startItemIndex + self.selectedIndexPath.item];
    }
    if (shouldPresentAsModal) {
        // Use modals, with smaller ones for iPad.
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
        navigationController.delegate = self;
        navigationController.view.backgroundColor = [UIColor whiteColor];
        if (layout.hasMultipleColumns) {
            navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        } else {
            navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
        }
        [self.navigationController presentViewController:navigationController animated:YES completion:nil];
    } else {
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
                             target:self action:@selector(updateDeleting:)];
    return _deleteButtonItem;
}

- (void)setNumberToDelete:(NSUInteger)numberToDelete
{
    // Will.
    BOOL shouldClear = numberToDelete == 0 && abs((int)numberToDelete - (int)self.numberToDelete) > 0;
    if (shouldClear) {
        NSLog(@"INFO: Clearing %lu pending deletes.", self.numberToDelete);
        [self clearNeedsDeletes:self];
    }
    // Set.
    _numberToDelete = numberToDelete;
}

- (void)setDeleting:(BOOL)deleting
{
    _deleting = deleting;
    // Did.
    self.numberToDelete = 0;
}

- (void)setUpDeleting
{
    self.numberToDelete = 0;
    //self.navigationItem.leftBarButtonItem = self.deleteButtonItem;
}

- (IBAction)updateDeleting:(id)sender
{
    if (sender == self.deleteButtonItem) {
        if (!self.isDeleting) {
            self.deleting = YES;
        } else if (self.numberToDelete > 0) {
            [self deleteHighlighted:sender];
        }
    }
    UIBarButtonItem *rightButtonItem = self.isDeleting ? self.cancelButtonItem : self.createButtonItem;
    [self.navigationItem setRightBarButtonItem:rightButtonItem animated:YES];
    for (NBPersonCellView *cell in self.collectionView.visibleCells) {
        [cell setDeleteSwitchVisible:self.isDeleting animated:YES];
    }
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
    // Guard.
    if (loadMoreState == _loadMoreState) { return; }
    // Will.
    NBScrollViewPullActionState previousState = self.loadMoreState;
    // Set.
    _loadMoreState = loadMoreState;
    // Did.
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
        // Auto-scroll to new page only if we actually have content overflow.
        CGFloat itemHeight = layout.itemSize.height;
        CGFloat pageHeight = ([paginationInfo numberOfItemsAtPage:paginationInfo.currentPageNumber]
                              * (layout.hasMultipleColumns ? (itemHeight / layout.numberOfColumnsInMultipleColumnLayout) : itemHeight)
                              + layout.headerReferenceSize.height);
        BOOL shouldAutoScroll = (layout.intrinsicContentSize.height + pageHeight) > scrollView.bounds.size.height + itemHeight;
        if (shouldAutoScroll) {
            CGPoint contentOffset = scrollView.contentOffset;
            contentOffset.y += MIN(pageHeight, layout.visibleCollectionViewHeight);
            [scrollView setContentOffset:contentOffset animated:YES];
            dispatch_async(dispatch_get_main_queue(), ^{ // Defer showing the indicator until offset animation finishes.
                scrollView.showsVerticalScrollIndicator = YES;
            });
        }
    } else {
        scrollView.showsVerticalScrollIndicator = !shouldHideIndicator;
    }
}

- (void)setUpPagination
{
    [self.collectionView addObserver:self forKeyPath:ContentOffsetKeyPath options:0 context:&observationContext];
    NBPeopleDataSource *dataSource = (id)self.dataSource;
    NBPeopleViewFlowLayout *layout = (id)self.collectionViewLayout;
    CGFloat numberOfItemsPerPage = 10;
    dataSource.paginationInfo.numberOfItemsPerPage = (layout.hasMultipleColumns
                                                      ? layout.numberOfColumnsInMultipleColumnLayout * numberOfItemsPerPage
                                                      : numberOfItemsPerPage);
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
                                              otherButtonTitles:NSLocalizedString(@"label.ok", nil), nil];
    [alertView show];
}

@end
