//
//  TweetCell.m
//  BDBOAuth1ManagerDemo
//
//  Created by Bradley Bergeron on 10/14/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import "TweetCell.h"


#pragma mark -
@implementation TweetCell

- (void)awakeFromNib
{
    self.userImage.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    self.userImage.layer.masksToBounds = YES;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
        self.userImage.layer.cornerRadius = self.userImage.frame.size.width / 2.0;
    else
        self.userImage.layer.cornerRadius = 5.0;
    self.userImage.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    self.userImage.layer.shouldRasterize = YES;
    self.userImage.clipsToBounds = YES;

    [self prepareForReuse];
}

- (void)prepareForReuse
{
    self.tweetLabel.text = nil;
    self.userImage.image = nil;
}

@end
