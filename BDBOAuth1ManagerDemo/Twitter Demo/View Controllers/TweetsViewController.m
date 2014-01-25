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

#import <UIKit+AFNetworking.h>

#import "AppDelegate.h"
#import "TweetCell.h"
#import "TweetsViewController.h"


#pragma mark -
@interface TweetsViewController ()

@property (nonatomic) NSMutableArray *tweets;
@property (nonatomic, strong) TweetCell *tweetCell;

- (void)logInOut;

@end


#pragma mark -
@implementation TweetsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Tweets";

    self.tableView.rowHeight = 72.0;

    UINib *tableCellNib = [UINib nibWithNibName:@"TweetCell" bundle:nil];
    [self.tableView registerNib:tableCellNib forCellReuseIdentifier:@"TweetCell"];
    self.tweetCell = [tableCellNib instantiateWithOwner:nil options:nil][0];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshFeed) forControlEvents:UIControlEventValueChanged];

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
        self.tableView.separatorInset = UIEdgeInsetsZero;

    NSString *logInOutString = ([[[AppDelegate sharedDelegate] networkManager] isAuthorized]) ? @"Log Out" : @"Log In";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:logInOutString
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(logInOut)];

    self.tweets = [NSMutableArray array];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ([[[AppDelegate sharedDelegate] networkManager] isAuthorized])
        [self refreshFeed];
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
        self.tweets = [NSMutableArray array];
        [self.tableView reloadData];
        [[AppDelegate sharedDelegate] deauthorizeWithCompletion:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.navigationItem.rightBarButtonItem.title = @"Log In";
            });
        }];
    }
}

#pragma mark Load Tweets
- (void)refreshFeed
{
    if (![[[AppDelegate sharedDelegate] networkManager] isAuthorized])
    {
        [self didLoadTweetsWithError:nil];
        return;
    }

    NSString *timeline = @"statuses/home_timeline.json?count=100";

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    BDBOAuth1SessionManager *manager = [[AppDelegate sharedDelegate] networkManager];
    [manager GET:timeline
      parameters:nil
         success:^(NSURLSessionDataTask *task, id responseObject) {
             self.tweets = (NSMutableArray *)responseObject;
             [self didLoadTweetsWithError:nil];
         }
         failure:^(NSURLSessionDataTask *task, NSError *error) {
             [self didLoadTweetsWithError:error];
         }];
#else
    BDBOAuth1RequestOperationManager *manager = [[AppDelegate sharedDelegate] networkManager];
    [manager GET:timeline
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             self.tweets = (NSMutableArray *)responseObject;
             [self didLoadTweetsWithError:nil];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [self didLoadTweetsWithError:error];
         }];
#endif
}

- (void)didLoadTweetsWithError:(NSError *)error
{
    [self.refreshControl endRefreshing];

    if (!error)
        [self.tableView reloadData];
    else
        NSLog(@"Error: %@", error);
}

#pragma mark TableView Data Source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tweets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TweetCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TweetCell" forIndexPath:indexPath];
    if (!cell)
        cell = [[TweetCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TweetCell"];

    NSDictionary *tweet = self.tweets[indexPath.row];
    cell.tweetLabel.text = tweet[@"text"];
    [cell.userImage setImageWithURL:[NSURL URLWithString:[tweet[@"user"][@"profile_image_url"] stringByReplacingOccurrencesOfString:@"_normal" withString:@"_bigger"]]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.tweetCell.frame.size.height;
}

@end
