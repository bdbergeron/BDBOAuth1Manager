//
//  TweetCell.m
//  BDBOAuth1RequestSerializerDemo
//
//  Created by Bradley Bergeron on 10/14/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import "TweetCell.h"


#pragma mark -
@implementation TweetCell

- (void)awakeFromNib
{
    [self prepareForReuse];
}

- (void)prepareForReuse
{
    self.tweetLabel.text = nil;
    self.userImage.image = nil;
}

@end
