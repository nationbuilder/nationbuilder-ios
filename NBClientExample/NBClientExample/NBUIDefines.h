//
//  NBUIDefines.h
//  NBClientExample
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <NBClient/NBDefines.h>

@class NBClient;
@class NBPaginationInfo;

@protocol NBViewDataSource;

extern NSString * const NBNibNameViewKey;
extern NSString * const NBNibNameCellViewKey;
extern NSString * const NBNibNameDecorationViewKey;
extern NSString * const NBNibNameSectionHeaderViewKey;
extern NSString * const NBNibNameSectionFooterViewKey;

extern NSString * const NBUIErrorTitleKey;
extern NSString * const NBUIErrorMessageKey;

extern NSString * const NBViewDataSourceErrorKeyPath;

typedef NS_ENUM(NSUInteger, NBScrollViewPullActionState) {
    NBScrollViewPullActionStateStopped,
    NBScrollViewPullActionStatePlanned,
    NBScrollViewPullActionStateInProgress,
};

#pragma mark - UIKit Protocols

// NOTE: These are not official protocols. They are just meant to be used by the
// sample app and clearly outline the MVC pattern used.

@protocol NBViewController <NBLogging>

@property (nonatomic, readonly) NSDictionary *nibNames;

// Dedicated initializer.
- (instancetype)initWithNibNames:(NSDictionary *)nibNamesOrNil bundle:(NSBundle *)nibBundleOrNil;

@optional

@property (nonatomic) id<NBViewDataSource> dataSource;

@property (nonatomic, getter = isBusy) BOOL busy;
@property (nonatomic) UIActivityIndicatorView *busyIndicator;
@property (nonatomic) UIBarButtonItem *cancelButtonItem;

- (IBAction)cancelPendingAction:(id)sender;

@end

@protocol NBViewCell <NBLogging>

- (void)refreshWithData:(NSDictionary *)data;

@optional

@property (nonatomic) id<NBViewDataSource> dataSource;

@end

@protocol NBCollectionViewCellDelegate <NSObject>

// Allow controller to always know when cell's visual state changes.
- (void)collectionViewCell:(UICollectionViewCell *)cell didSetSelected:(BOOL)selected;
- (void)collectionViewCell:(UICollectionViewCell *)cell didSetHighlighted:(BOOL)highlighted;

@optional

// Deletion support similar to table views.
- (void)collectionViewCell:(UICollectionViewCell *)cell didSetNeedsDelete:(BOOL)needsDelete;

@end

#pragma mark - Data Source Protocols

@protocol NBViewDataSource <NBLogging>

@property (nonatomic) NSError *error;

// Dedicated initializer.
- (instancetype)initWithClient:(NBClient *)client;

// Integrate with memory warnings.
- (void)cleanUp:(NSError **)error;

+ (NSError *)parseClientError:(NSError *)error;
+ (id)parseClientResults:(id)results;

@optional

@property (nonatomic, weak, readonly) NBClient *client;

@property (nonatomic, weak) id delegate;
@property (nonatomic) id changes;

+ (id)parseChanges:(id)changes;

@end

@protocol NBViewDataSourceDelegate <NSObject>

- (void)dataSource:(id<NBViewDataSource>)dataSource didChangeValueForKeyPath:(NSString *)keyPath;

@end

@protocol NBCollectionViewDataSource <NBViewDataSource>

@property (nonatomic) NBPaginationInfo *paginationInfo;

- (id<NBViewDataSource>)dataSourceForItem:(NSDictionary *)item;
- (id<NBViewDataSource>)dataSourceForItemAtIndex:(NSUInteger)index;

@end
