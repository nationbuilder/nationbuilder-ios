//
//  NBUIDefines.h
//  NBClientExample
//
//  Created by Peng Wang on 7/23/14.
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const NBNibNameViewKey;
extern NSString * const NBNibNameCellViewKey;
extern NSString * const NBNibNameDecorationViewKey;
extern NSString * const NBNibNameSectionHeaderViewKey;
extern NSString * const NBNibNameSectionFooterViewKey;

extern NSString * const NBUIErrorTitleKey;
extern NSString * const NBUIErrorMessageKey;

extern NSString * const NBDataSourceErrorKeyPath;

typedef NS_ENUM(NSUInteger, NBScrollViewPullActionState) {
    NBScrollViewPullActionStateStopped,
    NBScrollViewPullActionStatePlanned,
    NBScrollViewPullActionStateInProgress,
};

#pragma mark - UIKit Protocols

@protocol NBDataSource;

@protocol NBViewController <NSObject>

@property (nonatomic, strong, readonly) NSDictionary *nibNames;

// Dedicated initializer.
- (instancetype)initWithNibNames:(NSDictionary *)nibNamesOrNil bundle:(NSBundle *)nibBundleOrNil;

@optional

@property (nonatomic, strong) id<NBDataSource> dataSource;

@property (nonatomic, getter = isBusy) BOOL busy;
@property (nonatomic, strong) UIActivityIndicatorView *busyIndicator;
@property (nonatomic, strong) UIBarButtonItem *cancelButtonItem;

- (IBAction)cancelPendingAction:(id)sender;

@end

@protocol NBViewCell <NSObject>

- (void)refreshWithData:(NSDictionary *)data;

@optional

@property (nonatomic, strong) id<NBDataSource> dataSource;

@end

@protocol NBCollectionViewCellDelegate <NSObject>

// Allow controller to always know when cell's visual state changes.
- (void)collectionViewCell:(UICollectionViewCell *)cell didSetSelected:(BOOL)selected;
- (void)collectionViewCell:(UICollectionViewCell *)cell didSetHighlighted:(BOOL)highlighted;

// Deletion support similar to table views.
- (void)collectionViewCell:(UICollectionViewCell *)cell didSetNeedsDelete:(BOOL)needsDelete;

@end

#pragma mark - Data Source Protocols

@class NBClient;
@class NBPaginationInfo;

@protocol NBDataSource <NSObject>

@property (nonatomic, strong) NSError *error;

// Dedicated initializer.
- (instancetype)initWithClient:(NBClient *)client;

// Integrate with memory warnings.
- (void)cleanUp:(NSError **)error;

+ (NSError *)parseClientError:(NSError *)error;
+ (id)parseClientResults:(id)results;

@optional

@property (nonatomic, weak, readonly) NBClient *client;

@property (nonatomic, weak) id<NBDataSource> parentDataSource;

@property (nonatomic, strong) id changes;

+ (id)parseChanges:(id)changes;

@end

@protocol NBCollectionDataSource <NBDataSource>

@property (nonatomic, strong) NBPaginationInfo *paginationInfo;

- (id<NBDataSource>)dataSourceForItem:(NSDictionary *)item;
- (id<NBDataSource>)dataSourceForItemAtIndex:(NSUInteger)index;

@end
