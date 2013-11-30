//
//  PhotosViewController.h
//  BDBOAuth1ManagerDemo
//
//  Created by Bradley Bergeron on 11/10/2013.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import <UIKit/UIKit.h>


#pragma mark -
@interface PhotosViewController : UICollectionViewController
<UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate, UIActionSheetDelegate>

- (void)loadImages;

@end
