//
//  TweetCell.m
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

#import "TweetCell.h"

#pragma mark -
@implementation TweetCell

- (void)awakeFromNib {
    self.userImageView.layer.masksToBounds = YES;

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        self.userImageView.layer.cornerRadius = self.userImageView.frame.size.width / 2.0f;
    } else {
        self.userImageView.layer.cornerRadius = 5.0f;
    }
    
    self.userImageView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    self.userImageView.layer.shouldRasterize = YES;
    self.userImageView.clipsToBounds = YES;

    [self prepareForReuse];
}

- (void)prepareForReuse {
    self.userImageView.image = nil;
    self.userNameLabel.text = @"";
    self.userScreenNameLabel.text = @"@";
    self.tweetLabel.text = nil;
}

@end
