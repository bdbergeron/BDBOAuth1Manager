//
//  TweetsViewController.m
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
#import "BDBTweet.h"
#import "BDBTwitterClient.h"
#import "TweetCell.h"
#import "TweetsViewController.h"

#import "AFNetworking/UIKit+AFNetworking.h"
#import "BBlock/UIKit+BBlock.h"


static NSString * const kTweetCellName = @"TweetCell";


#pragma mark -
@interface TweetsViewController ()

@property (nonatomic) NSMutableDictionary *offscreenCells;
@property (nonatomic) NSArray *tweets;

- (void)logInOut;

@end

#pragma mark -
@implementation TweetsViewController

- (id)init {
    self = [super init];

    if (self) {
        _offscreenCells = [NSMutableDictionary dictionary];
        _tweets = [NSArray array];

        self.refreshControl = [UIRefreshControl new];
        [self.refreshControl addTarget:self action:@selector(loadTweets) forControlEvents:UIControlEventValueChanged];

        self.tableView.rowHeight = 90.0f;

        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f) {
            self.tableView.separatorInset = UIEdgeInsetsZero;
        }

        [[NSNotificationCenter defaultCenter] addObserverForName:BDBTwitterClientDidLogInNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            [self loadTweets];

            [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Log Out", nil)];
        }];

        [[NSNotificationCenter defaultCenter] addObserverForName:BDBTwitterClientDidLogOutNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            self.tweets = [NSArray array];

            [self.tableView reloadData];

            [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Log In", nil)];
        }];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Tweets", nil);

    UINib *tableCellNib = [UINib nibWithNibName:kTweetCellName bundle:nil];
    [self.tableView registerNib:tableCellNib forCellReuseIdentifier:kTweetCellName];

    NSString *logInOutString = ([[BDBTwitterClient sharedClient] isAuthorized]) ?
        NSLocalizedString(@"Log Out", nil) : NSLocalizedString(@"Log In", nil);

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:logInOutString
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(logInOut)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if ([[BDBTwitterClient sharedClient] isAuthorized]) {
        [self loadTweets];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Authorization
- (void)logInOut {
    if ([[BDBTwitterClient sharedClient] isAuthorized]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to log out?", nil)
                                cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                           destructiveButtonTitle:NSLocalizedString(@"Log Out", nil)
                                 otherButtonTitle:nil
                                  completionBlock:^(NSInteger buttonIndex, UIActionSheet *actionSheet) {
                                      if (buttonIndex == actionSheet.destructiveButtonIndex) {
                                          [[BDBTwitterClient sharedClient] deauthorize];
                                      }
                                 }]
             showInView:self.view];
        });
    } else {
        [[BDBTwitterClient sharedClient] authorize];
    }
}

#pragma mark Load Tweets
- (void)loadTweets {
    if (![[BDBTwitterClient sharedClient] isAuthorized]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Not Logged In", nil)
                                        message:NSLocalizedString(@"You have to log in before you can view your timeline!", nil)
                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                               otherButtonTitle:NSLocalizedString(@"Log In", nil)
                                completionBlock:^(NSInteger buttonIndex, UIAlertView *alertView) {
                                    if (buttonIndex == alertView.cancelButtonIndex + 1) {
                                        [[BDBTwitterClient sharedClient] authorize];
                                    }
                                }]
             show];
        });

        [self.refreshControl endRefreshing];

        return;
    }

    if (!self.refreshControl.isRefreshing) {
        [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y - self.refreshControl.frame.size.height)
                                animated:NO];
        [self.refreshControl beginRefreshing];
    }

    [[BDBTwitterClient sharedClient] loadTimelineWithCompletion:^(NSArray *tweets, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error.localizedDescription);

            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                            message:error.localizedDescription
                                           delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                                  otherButtonTitles:nil] show];
            });
        } else {
            self.tweets = tweets;

            [self.tableView reloadData];
        }

        [self.refreshControl endRefreshing];
    }];
}

#pragma mark TableView Data Source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tweets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TweetCell *cell = [tableView dequeueReusableCellWithIdentifier:kTweetCellName forIndexPath:indexPath];

    BDBTweet *tweet = self.tweets[indexPath.row];

    cell.userNameLabel.text = tweet.userName;
    cell.userScreenNameLabel.text = [NSString stringWithFormat:@"@%@", tweet.userScreenName];
    cell.tweetLabel.text = tweet.tweetText;

    NSURL *userImageURL = tweet.userImageURL;

    if (userImageURL) {
        __weak TweetCell *weakCell = cell;
        [weakCell.userImageView setImageWithURLRequest:[NSURLRequest requestWithURL:tweet.userImageURL]
                                      placeholderImage:nil
                                               success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                   weakCell.userImageView.image = image;
                                               }
                                               failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                   NSLog(@"Failed to load image for cell. %@", error.localizedDescription);
                                               }];
    }

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    TweetCell *cell = [self.offscreenCells objectForKey:kTweetCellName];

    if (!cell) {
        cell = [[[UINib nibWithNibName:kTweetCellName bundle:nil] instantiateWithOwner:nil options:nil] objectAtIndex:0];
        [self.offscreenCells setObject:cell forKey:kTweetCellName];
    }

    BDBTweet *tweet = self.tweets[indexPath.row];

    cell.userNameLabel.text = tweet.userName;
    cell.userScreenNameLabel.text = [NSString stringWithFormat:@"@%@", tweet.userScreenName];
    cell.tweetLabel.text = tweet.tweetText;

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];

    cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));

    [cell setNeedsLayout];
    [cell layoutIfNeeded];

    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;

    return height + 1.0f;
}

@end
