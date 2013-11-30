//
//  PhotoAlbumHeaderView.h
//  BDBOAuth1ManagerDemo
//
//  Created by Bradley Bergeron on 8/15/13.
//  Copyright (c) 2013 Bradley Bergeron. All rights reserved.
//

#import <UIKit/UIKit.h>


#pragma mark -
@interface PhotoAlbumHeaderView : UICollectionReusableView

@property (weak, nonatomic) IBOutlet UIView     *backgroundView;
@property (weak, nonatomic) IBOutlet UILabel    *albumTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel    *photoCountLabel;

@end
