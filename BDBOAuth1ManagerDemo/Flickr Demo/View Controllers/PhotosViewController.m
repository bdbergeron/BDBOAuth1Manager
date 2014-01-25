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
#import "FLClient.h"
#import "PhotoAlbumCell.h"
#import "PhotoAlbumHeaderView.h"
#import "PhotoAlbumLayout.h"
#import "PhotosViewController.h"

#import "UIImageView+AFNetworking.h"


#pragma mark -
@interface PhotosViewController ()

@property (nonatomic) UIRefreshControl *refreshControl;

@property (nonatomic) UINib *photoAlbumHeaderNib;
@property (nonatomic) PhotoAlbumHeaderView *photoAlbumHeader;

@property (nonatomic) NSInteger numberOfSetsLoading;

@property (nonatomic) NSSet *photosets;
@property (nonatomic) NSArray *sortedPhotosets;

- (void)logInOut;

@end


#pragma mark -
@implementation PhotosViewController

- (id)init
{
    PhotoAlbumLayout *photosLayout = [[PhotoAlbumLayout alloc] init];
    photosLayout.scrollDirection = UICollectionViewScrollDirectionVertical;

    self = [super initWithCollectionViewLayout:photosLayout];
    if (self)
    {
        self.collectionView.backgroundColor = [UIColor whiteColor];
        self.collectionView.alwaysBounceVertical = YES;

        _photosets       = [NSSet set];
        _sortedPhotosets = [NSArray array];
        _numberOfSetsLoading = 0;

        _refreshControl = [[UIRefreshControl alloc] init];
        [_refreshControl addTarget:self action:@selector(loadImages) forControlEvents:UIControlEventValueChanged];
        [self.collectionView addSubview:_refreshControl];

        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
            self.edgesForExtendedLayout = UIRectEdgeNone;

        [FLClient clientWithAPIKey:[[AppDelegate sharedDelegate] apiKey] networkManager:[[AppDelegate sharedDelegate] networkManager]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Photos";

    self.photoAlbumHeaderNib = [UINib nibWithNibName:@"PhotoAlbumHeaderView" bundle:[NSBundle mainBundle]];
    self.photoAlbumHeader = [self.photoAlbumHeaderNib instantiateWithOwner:nil options:nil][0];

    [self.collectionView registerClass:[PhotoAlbumCell class] forCellWithReuseIdentifier:@"PhotoAlbumCell"];
    [self.collectionView registerNib:self.photoAlbumHeaderNib
          forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                 withReuseIdentifier:@"PhotoAlbumHeaderView"];

    NSString *logInOutString = ([[[AppDelegate sharedDelegate] networkManager] isAuthorized]) ? @"Log Out" : @"Log In";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:logInOutString
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(logInOut)];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ([[[AppDelegate sharedDelegate] networkManager] isAuthorized])
        [self loadImages];
}

#pragma mark Authorization
- (void)logInOut
{
    if ([[[AppDelegate sharedDelegate] networkManager] isAuthorized])
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIActionSheet alloc] initWithTitle:@"Are you sure you want to log out?"
                                         delegate:self
                                cancelButtonTitle:@"Cancel"
                           destructiveButtonTitle:@"Log Out"
                                otherButtonTitles:nil] showInView:self.view];
        });
    else
        [[AppDelegate sharedDelegate] authorize];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex)
    {
        self.photosets = [NSMutableSet set];
        self.sortedPhotosets = [NSArray array];
        [self.collectionView reloadData];
        [[AppDelegate sharedDelegate] deauthorizeWithCompletion:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.navigationItem.rightBarButtonItem.title = @"Log In";
            });
        }];
    }
}

#pragma mark Load Images
- (void)loadImages
{
    if (!self.refreshControl.isRefreshing)
        [self.refreshControl beginRefreshing];
    [self loadPhotosets];
}

- (void)loadPhotosets
{
    [[FLClient sharedClient] getPhotosetsWithCompletion:^(NSSet *photosets, NSError *error) {
        if (!error)
        {
            self.photosets = photosets;
            for (FLPhotoset *photoset in photosets)
                [self loadPhotosInSet:photoset];
        }
        else
        {
            NSLog(@"Error: %@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"Error"
                                            message:error.localizedDescription
                                           delegate:self
                                  cancelButtonTitle:@"Dismiss"
                                  otherButtonTitles:nil] show];
            });
        }
    }];
}

- (void)loadPhotosInSet:(FLPhotoset *)photoset
{
    [[FLClient sharedClient] getPhotosInPhotoset:photoset completion:^(NSArray *photos, NSError *error) {
        if (!error)
        {
            photoset.photos = photos;
        }
        else
        {
            NSLog(@"Error: %@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"Error"
                                            message:error.localizedDescription
                                           delegate:self
                                  cancelButtonTitle:@"Dismiss"
                                  otherButtonTitles:nil] show];
            });
        }
        [self sortPhotosets];
    }];
}

- (void)sortPhotosets
{
    self.sortedPhotosets = [self.photosets.allObjects sortedArrayUsingComparator:^NSComparisonResult(FLPhotoset *set1, FLPhotoset *set2) {
        return [set1.dateCreated compare:set2.dateCreated];
    }];

    [self.collectionView reloadData];
    self.collectionView.scrollEnabled = YES;
    [self.refreshControl endRefreshing];
}

#pragma mark CollectionView DataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.sortedPhotosets.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    FLPhotoset *photoset =  self.sortedPhotosets[section];
    return photoset.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoAlbumCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoAlbumCell"
                                                                     forIndexPath:indexPath];

    FLPhotoset *photosetForCell = self.sortedPhotosets[indexPath.section];
    FLPhoto *photo = photosetForCell.photos[indexPath.row];

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
                                 atIndexPath:(NSIndexPath *)indexPath
{
    FLPhotoset *photosetForCell = self.sortedPhotosets[indexPath.section];

    PhotoAlbumHeaderView *headerView =
    [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                       withReuseIdentifier:@"PhotoAlbumHeaderView"
                                              forIndexPath:indexPath];

    headerView.albumTitleLabel.text = photosetForCell.title;
    headerView.photoCountLabel.text = [NSString stringWithFormat:@"%i photos", photosetForCell.photos.count];

    return headerView;
}

#pragma mark CollectionView Layout Delegate
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat padding = [self collectionView:collectionView
                                    layout:collectionViewLayout
  minimumInteritemSpacingForSectionAtIndex:indexPath.section];

    CGFloat collectionWidth = self.view.bounds.size.width - padding * (4 - 1);
    CGFloat imageWidth = collectionWidth / 4;

    return CGSizeMake(imageWidth, imageWidth);
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section
{
    return self.photoAlbumHeader.bounds.size;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 3.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return [self collectionView:collectionView layout:collectionViewLayout minimumInteritemSpacingForSectionAtIndex:section];
}

@end
