//
//  PhotoGridViewController.h
//
//  Created by David Charlec on 05/11/11.
//  Copyright (c) 2011 Pulpfingers. All rights reserved.
//

#import <UIKit/UIKit.h>

#define NUMBER_OF_COLUMNS 3

@protocol PFGridViewDelegate;
@protocol PFGridViewDataSource;

@interface PFGridView : UITableViewController {
    NSInteger numberOfRows;
    NSInteger numberOfItems;

    BOOL dataIsBeingFetched;
    BOOL dataHasBeenLoaded;

    PF500PhotoRequest *request;
    UILabel *noPhotoLabel;
    UIViewController *viewController;
}

@property(assign) id<PFGridViewDelegate> delegate;
@property(assign) id<PFGridViewDataSource> dataSource;
@property(nonatomic, retain) EGORefreshTableHeaderView *refreshTableHeader;
@property NSInteger numberOfColumns;

- (id)initWithPhotoRequest:(PF500PhotoRequest*)photoRequest andViewController:(UIViewController*)viewController;
- (void)simulatePullToRefresh;
@end

@protocol PFGridViewDataSource <NSObject>
@required
- (NSInteger)numberOfItemsInGrid:(PFGridView *)gridView;
- (UITableViewCell *)cellForIndexPath:(NSIndexPath)indexPath;
@end

@protocol PFGridViewDelegate <NSObject>
@required
- (void)userDidLogin;
- (void)userDidNotLogin:(BOOL)userCancellation;
- (void)requestDidFailWithError:(FacebookError *)error;
- (void)requestDidSucceedWithResult:(id)result;
@end