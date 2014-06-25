//
//  PhotosViewController.m
//
//  Copyright (c) 2014 Bradley David Bergeron
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "AppDelegate.h"
#import "BDBFlickrClient.h"
#import "BDBFlickrPhoto.h"
#import "BDBFlickrPhotoset.h"
#import "PhotoAlbumCell.h"
#import "PhotoAlbumHeaderView.h"
#import "PhotoAlbumLayout.h"
#import "PhotosViewController.h"

#import "AFNetworking/UIImageView+AFNetworking.h"
#import "BBlock/UIKit+BBlock.h"


static NSString * const kPhotoAlbumHeaderViewReuseIdentifier = @"PhotoAlbumHeaderView";
static NSString * const kPhotoAlbumPhotoCellReuseIdentifier  = @"PhotoAlbumCell";


#pragma mark -
@interface PhotosViewController ()

@property (nonatomic) UIRefreshControl *refreshControl;

@property (nonatomic) UINib *photoAlbumHeaderNib;
@property (nonatomic) PhotoAlbumHeaderView *photoAlbumHeader;

@property (nonatomic) NSSet *photosets;
@property (nonatomic) NSArray *sortedPhotosets;
@property (nonatomic) NSUInteger numberOfSetsLoading;

@property (nonatomic) NSUInteger imagesPerRow;

- (void)logInOut;

@end

#pragma mark -
@implementation PhotosViewController

- (id)init {
    PhotoAlbumLayout *photosLayout = [PhotoAlbumLayout new];
    photosLayout.scrollDirection = UICollectionViewScrollDirectionVertical;

    self = [super initWithCollectionViewLayout:photosLayout];

    if (self) {
        // Instantiate ivars
        _photosets       = [NSSet set];
        _sortedPhotosets = [NSArray array];
        _numberOfSetsLoading = 0;

        _refreshControl = [UIRefreshControl new];
        [_refreshControl addTarget:self action:@selector(loadImages) forControlEvents:UIControlEventValueChanged];
        [self.collectionView addSubview:_refreshControl];

        // Configure collection view
        self.collectionView.backgroundColor = [UIColor whiteColor];
        self.collectionView.alwaysBounceVertical = YES;

        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
            self.edgesForExtendedLayout = UIRectEdgeNone;
        }

        // Register for notifications
        [[NSNotificationCenter defaultCenter] addObserverForName:BDBFlickrClientDidLogInNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            [self loadImages];

            [self updateLogInOutButton];
        }];

        [[NSNotificationCenter defaultCenter] addObserverForName:BDBFlickrClientDidLogOutNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            self.photosets = [NSMutableSet set];
            self.sortedPhotosets = [NSArray array];

            [self.collectionView reloadData];

            [self updateLogInOutButton];
        }];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Photos", nil);

    self.photoAlbumHeaderNib = [UINib nibWithNibName:kPhotoAlbumHeaderViewReuseIdentifier bundle:[NSBundle mainBundle]];
    self.photoAlbumHeader = [self.photoAlbumHeaderNib instantiateWithOwner:nil options:nil][0];
    [self.collectionView registerNib:self.photoAlbumHeaderNib
          forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                 withReuseIdentifier:kPhotoAlbumHeaderViewReuseIdentifier];

    [self.collectionView registerClass:[PhotoAlbumCell class] forCellWithReuseIdentifier:kPhotoAlbumPhotoCellReuseIdentifier];

    [self updateLogInOutButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if ([[BDBFlickrClient sharedClient] isAuthorized]) {
        [self loadImages];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        self.imagesPerRow = 4;
    } else if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        self.imagesPerRow = 6;
    } else {
        self.imagesPerRow = 10;
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.collectionViewLayout invalidateLayout];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Authorization
- (void)logInOut {
    if ([[BDBFlickrClient sharedClient] isAuthorized]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to log out?", nil)
                                cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                           destructiveButtonTitle:NSLocalizedString(@"Log Out", nil)
                                 otherButtonTitle:nil
                                  completionBlock:^(NSInteger buttonIndex, UIActionSheet *actionSheet) {
                                      if (buttonIndex == actionSheet.destructiveButtonIndex) {
                                          [[BDBFlickrClient sharedClient] deauthorize];
                                      }
                                  }]
             showInView:self.view];
        });
    } else {
        [[BDBFlickrClient sharedClient] authorize];
    }
}

- (void)updateLogInOutButton {
    NSString *logInOutString = ([[BDBFlickrClient sharedClient] isAuthorized]) ?
        NSLocalizedString(@"Log Out", nil) : NSLocalizedString(@"Log In", nil);

    if (self.navigationItem.rightBarButtonItem) {
        [self.navigationItem.rightBarButtonItem setTitle:logInOutString];
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:logInOutString
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(logInOut)];
    }
}

#pragma mark Load Images
- (void)loadImages {
    if (![[BDBFlickrClient sharedClient] isAuthorized]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Not Logged In", nil)
                                        message:NSLocalizedString(@"You have to log in before you can view your photos!", nil)
                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                               otherButtonTitle:NSLocalizedString(@"Log In", nil)
                                completionBlock:^(NSInteger buttonIndex, UIAlertView *alertView) {
                                    if (buttonIndex == alertView.cancelButtonIndex + 1) {
                                        [[BDBFlickrClient sharedClient] authorize];
                                    }
                                }]
             show];
        });

        [self.refreshControl endRefreshing];

        return;
    }

    if (!self.refreshControl.isRefreshing) {
        [self.collectionView setContentOffset:CGPointMake(0, self.collectionView.contentOffset.y - self.refreshControl.frame.size.height)
                                     animated:NO];
        [self.refreshControl beginRefreshing];
    }

    [self loadPhotosets];
}

- (void)loadPhotosets {
    [[BDBFlickrClient sharedClient] getPhotosetsWithCompletion:^(NSSet *photosets, NSError *error) {
        if (!error) {
            self.photosets = photosets;
            self.numberOfSetsLoading = photosets.count;

            for (BDBFlickrPhotoset *photoset in photosets) {
                [self loadPhotosInSet:photoset];
            }
        } else {
            NSLog(@"Error: %@", error.localizedDescription);

            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                            message:error.localizedDescription
                                           delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                                  otherButtonTitles:nil] show];
            });
        }
    }];
}

- (void)loadPhotosInSet:(BDBFlickrPhotoset *)photoset {
    [[BDBFlickrClient sharedClient] getPhotosInPhotoset:photoset completion:^(NSArray *photos, NSError *error) {
        self.numberOfSetsLoading--;

        if (!error) {
            photoset.photos = photos;
        } else {
            NSLog(@"Error: %@", error.localizedDescription);

            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                            message:error.localizedDescription
                                           delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                                  otherButtonTitles:nil] show];
            });
        }

        if (self.numberOfSetsLoading == 0) {
            [self sortPhotosets];
        }
    }];
}

- (void)sortPhotosets {
    self.sortedPhotosets = [self.photosets.allObjects sortedArrayUsingComparator:^NSComparisonResult(BDBFlickrPhotoset *set1, BDBFlickrPhotoset *set2) {
        return [set1.dateCreated compare:set2.dateCreated];
    }];

    [self.collectionView reloadData];
    self.collectionView.scrollEnabled = YES;

    [self.refreshControl endRefreshing];
}

#pragma mark CollectionView DataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.sortedPhotosets.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    BDBFlickrPhotoset *photoset =  self.sortedPhotosets[section];

    return photoset.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoAlbumCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPhotoAlbumPhotoCellReuseIdentifier
                                                                     forIndexPath:indexPath];

    BDBFlickrPhotoset *photosetForCell = self.sortedPhotosets[indexPath.section];
    BDBFlickrPhoto *photo = photosetForCell.photos[indexPath.row];

    [cell.activityIndicator startAnimating];

    __weak PhotoAlbumCell *weakCell = cell;
    [weakCell.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:photo.thumbnailURL]
                              placeholderImage:nil
                                       success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                           weakCell.imageView.image = image;

                                           [weakCell.activityIndicator stopAnimating];
                                       }
                                       failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                           NSLog(@"Failed to load image for cell. %@", error.localizedDescription);

                                           [weakCell.activityIndicator stopAnimating];
                                       }];

    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    BDBFlickrPhotoset *photosetForCell = self.sortedPhotosets[indexPath.section];

    PhotoAlbumHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                          withReuseIdentifier:kPhotoAlbumHeaderViewReuseIdentifier
                                                                                 forIndexPath:indexPath];

    headerView.albumTitleLabel.text = photosetForCell.title;
    headerView.photoCountLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu photos", nil), (unsigned long)photosetForCell.photos.count];

    return headerView;
}

#pragma mark CollectionView Layout Delegate
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat padding = [self collectionView:collectionView
                                    layout:collectionViewLayout
  minimumInteritemSpacingForSectionAtIndex:indexPath.section];

    CGFloat collectionWidth = self.view.bounds.size.width - padding * (self.imagesPerRow - 1);
    CGFloat imageWidth = collectionWidth / self.imagesPerRow;

    return CGSizeMake(imageWidth, imageWidth);
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section {
    return self.photoAlbumHeader.bounds.size;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 3.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return [self collectionView:collectionView layout:collectionViewLayout minimumInteritemSpacingForSectionAtIndex:section];
}

@end
