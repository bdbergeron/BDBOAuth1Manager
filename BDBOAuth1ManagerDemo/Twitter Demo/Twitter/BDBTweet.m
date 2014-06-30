//
//  BDBTweet.m
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

#import "BDBTweet.h"


static NSString * const kBDBTweetTweetTextName = @"text";
static NSString * const kBDBTweetUserInfoName = @"user";
static NSString * const kBDBTweetUserImageURLName = @"profile_image_url";
static NSString * const kBDBTweetUserNameName = @"name";
static NSString * const kBDBTweetUserScreenNameName = @"screen_name";

#pragma mark -
@implementation BDBTweet

- (id)initWithDictionary:(NSDictionary *)tweetInfo {
    self = [super init];

    if (self) {
        _tweetText = [tweetInfo[kBDBTweetTweetTextName] copy];

        NSDictionary *userInfo = tweetInfo[kBDBTweetUserInfoName];

        if (userInfo[kBDBTweetUserImageURLName]) {
            NSString *userImageURLString = [userInfo[kBDBTweetUserImageURLName] stringByReplacingOccurrencesOfString:@"_normal"
                                                                                                          withString:@"_bigger"];
            _userImageURL = [NSURL URLWithString:userImageURLString];
        }

        _userName = userInfo[kBDBTweetUserNameName];
        _userScreenName = userInfo[kBDBTweetUserScreenNameName];
    }
    
    return self;
}

@end
