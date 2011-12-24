//
//  PFGridView.m
//
//  Created by David Charlec on 23/12/11.
//  Copyright (c) 2011 Pulpfingers. All rights reserved.
//

#import "PFGridView.h"
#import "PhotoNavigatorViewController.h"

@interface PFGridView (Private)

- (void)reloadPhotos;
- (void)loadNextPage:(id)sender;
- (void)resetTableHeader;
- (void)buildTableViewFooter;

@end

@implementation PFGridView

@synthesize delegate;
@synthesize photos;
@synthesize refreshTableHeader;

- (id)initWithPhotoRequest:(PF500PhotoRequest *)photoRequest andViewController:(UIViewController *)rootViewController {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        // Custom initialization
        self.photos = [NSArray array];
        viewController = [rootViewController retain];
        request = [photoRequest retain];
        [request setPage:1];
        [request setPerPage:99];
        request.delegate = self;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    }
    return self;

}

- (void)buildTableViewFooter {
    if(request.totalPageCount > request.page) {
        UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        moreButton.frame = CGRectMake(0.0, 15.0, 320.0, 42.0);

        [moreButton addTarget:self 
                       action:@selector(loadNextPage:)
             forControlEvents:UIControlEventTouchDown];
        
        [moreButton setTitle:NSLocalizedString(@"Load more photos...", nil) forState:UIControlStateNormal];        
        [moreButton setBackgroundImage:[UIImage imageNamed:@"large-button-light-background.png"] forState:UIControlStateNormal];
        [moreButton.titleLabel setShadowColor:[UIColor lightGrayColor]];
        [moreButton.titleLabel setShadowOffset:CGSizeMake(0, 1)];
        [moreButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16.0]];
        [moreButton.titleLabel setTextAlignment:UITextAlignmentCenter];
        
        UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 150.0)];
        
        [loadMorePhotosIndicatorView setCenter:CGPointMake(160.0, 30.0)];
        [loadMorePhotosIndicatorView stopAnimating];
        [contentView addSubview:loadMorePhotosIndicatorView];
        [contentView addSubview:moreButton];
        self.tableView.tableFooterView = [contentView autorelease];
    } else {
        self.tableView.tableFooterView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 55.0)] autorelease];
    }
    
}

- (void)didRotate:(NSNotification *)notification {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationPortraitUpsideDown) return;
    
    numberOfColumns = 3;
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        numberOfColumns = 4;
    } 
    [self.tableView reloadData];
}

- (void)loadNextPage:(id)sender {    
    if(sender) {
        UIButton *button = (UIButton*)sender;
        [button setHidden:YES];
    }
    [loadMorePhotosIndicatorView startAnimating];
    [request fetchNextPage];
}

- (void)reloadPhotos {    
    [request setPage:1];
    [request fetch];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)resetTableHeader {
    [refreshTableHeader egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];        
    dataIsBeingFetched = NO;    
}

- (void)simulatePullToRefresh {
    if(!dataHasBeenLoaded) {
        [self.tableView setContentOffset:CGPointMake(0, -66) animated:NO];
        [refreshTableHeader egoRefreshScrollViewDidEndDragging:self.tableView];       
    }
}

#pragma mark -
#pragma mark UITableView delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    numberOfRows = [self.photos count] / numberOfColumns;    
    // if on last page
    if(request.page == request.totalPageCount) {
        if(([self.photos count] % numberOfColumns) > 0) numberOfRows++;	
    }

    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *SimpleTableIdentifier = @"ThumbnailCell";
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    PhotoGridTableViewCell *cell = (PhotoGridTableViewCell*)[tableView dequeueReusableCellWithIdentifier:SimpleTableIdentifier];
    
    if(!cell) {
        cell = [[[PhotoGridTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SimpleTableIdentifier interfaceOrientation:orientation] autorelease];
    }
    
    NSInteger firstPhotoPosition = (indexPath.row * numberOfColumns) + 1;
	NSInteger lastPhotoPosition = firstPhotoPosition + (numberOfColumns - 1);	
    
    // This is the last page
    if(request.page == request.totalPageCount) {
        if(lastPhotoPosition > [self.photos count]) lastPhotoPosition = [self.photos count];
    }
    
	for (int i = firstPhotoPosition; i <= lastPhotoPosition; i++) {
        PF500Photo *photo = [self.photos objectAtIndex:i - 1];
        [cell setPhoto: photo atPosition:i];
	}
    
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {    
    PhotoGridTableViewCell *cell = (PhotoGridTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
    if(cell.selectedIndex > -1) {

        PhotoNavigatorViewController *photoNavigatorViewController = [[PhotoNavigatorViewController alloc] initWithPhotoArray:self.photos atIndex:cell.selectedIndex];
        photoNavigatorViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;        
        [viewController.navigationController pushViewController:photoNavigatorViewController animated:YES];
        [photoNavigatorViewController release];
        
    }
}

#pragma mark -
#pragma mark UIScrollView delegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	[refreshTableHeader egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {	
	[refreshTableHeader egoRefreshScrollViewDidEndDragging:scrollView];	
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate delegate methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view {
    [self reloadPhotos];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view {
    return dataIsBeingFetched;
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view {	
	return [NSDate date];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.tableView setRowHeight:105.0];
    [self.tableView setAllowsSelection:YES];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    loadMorePhotosIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];        
    [loadMorePhotosIndicatorView setHidesWhenStopped:YES];
    
    refreshTableHeader = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
    refreshTableHeader.delegate = self;
    refreshTableHeader.backgroundColor = [UIColor clearColor];
    [self.tableView addSubview:refreshTableHeader];
    
    [refreshTableHeader refreshLastUpdatedDate];
    
    noPhotoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 40.0)];
    [noPhotoLabel setBackgroundColor:[UIColor clearColor]];
    [noPhotoLabel setText:NSLocalizedString(@"No photos...", nil)];
    [noPhotoLabel setTextColor:[UIColor lightGrayColor]];
    [noPhotoLabel setHidden:YES];
    [noPhotoLabel setTextAlignment:UITextAlignmentCenter];
    [noPhotoLabel setCenter:CGPointMake(self.tableView.frame.size.width / 2, self.tableView.frame.size.height /2)];
    [self.tableView addSubview:noPhotoLabel];
    
    // force numberOfColumns initialization
    [self didRotate:nil];
        
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}


#pragma mark -

- (void)photoRequest:(PF500PhotoRequest *)request didLoadPhotos:(NSArray *)pfPhotos {
    dataHasBeenLoaded = YES;
    [self performSelector:@selector(resetTableHeader) withObject:nil afterDelay:0.5];
    self.photos = pfPhotos;
    [noPhotoLabel setHidden:([self.photos count] > 0)];
    [self.tableView reloadData];
    [self buildTableViewFooter];

}

- (void)photoRequest:(PF500PhotoRequest *)request didFailWithError:(PF500Error *)error {
    dataHasBeenLoaded = NO;
    [self performSelector:@selector(resetTableHeader) withObject:nil afterDelay:0.5];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network connection", nil) message:@"We were unable to load data from 500px. Please check your internet connection. You can retry by pulling the list." delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles: nil];
    [alertView show];
    [alertView release];
    [self buildTableViewFooter];
    
}

- (void)dealloc {
    if(loadMorePhotosIndicatorView) [loadMorePhotosIndicatorView release];
    [refreshTableHeader release];
    [viewController release];
    [request setDelegate:nil];
    [request release];
    [refreshTableHeader release];
    [photos release];
    [noPhotoLabel release];
    [super dealloc];
}


@end
