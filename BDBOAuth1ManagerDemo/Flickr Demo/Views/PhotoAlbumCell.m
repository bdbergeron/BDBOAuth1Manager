//
//  PhotoAlbumCell.m
//  BDBOAuth1ManagerDemo
//
//  Created by Brad Bergeron on 7/16/13.
//  Copyright (c) 2013 Bradley Bergeron. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "PhotoAlbumCell.h"


#pragma mark -
@implementation PhotoAlbumCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.contentView.clipsToBounds = YES;

        self.activityIndicator = [[UIActivityIndicatorView alloc] init];
        self.activityIndicator.center = self.contentView.center;
        self.activityIndicator.hidesWhenStopped = YES;
        [self.contentView addSubview:self.activityIndicator];

        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:self.imageView];
    }
    return self;
}

- (void)prepareForReuse
{
    self.imageView.image = nil;
}

@end
