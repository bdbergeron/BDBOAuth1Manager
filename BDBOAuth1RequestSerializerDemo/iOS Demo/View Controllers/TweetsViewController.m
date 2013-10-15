//
//  TweetsViewController.m
//  BDBOAuth1RequestSerializerDemo
//
//  Created by Bradley Bergeron on 11/10/2013.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import "AppDelegate.h"
#import "TweetCell.h"
#import "TweetsViewController.h"


#pragma mark -
@interface TweetsViewController ()

@property (nonatomic) NSMutableArray *tweets;

@property (nonatomic, weak) TweetCell *tweetCell;

@end


#pragma mark -
@implementation TweetsViewController

- (void)loadView
{
    [super loadView];
    self.title = @"Tweets";
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorInset = UIEdgeInsetsZero;

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(loadTweets) forControlEvents:UIControlEventValueChanged];

    UINib *tableCellNib = [UINib nibWithNibName:@"TweetCell" bundle:nil];
    [self.tableView registerNib:tableCellNib forCellReuseIdentifier:@"TweetCell"];
    self.tweetCell = [tableCellNib instantiateWithOwner:nil options:nil][0];

    self.tweets = [NSMutableArray array];

    [self loadTweets];
}

#pragma mark Load Tweets
- (void)loadTweets
{
    NSURL *twitterAPIURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/"];

#ifdef __IPHONE_8_0
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:twitterAPIURL];
    manager.requestSerializer = [[AppDelegate sharedDelegate] requestSerializer];
    [manager GET:@"statuses/home_timeline.json"
      parameters:nil
         success:^(NSURLSessionDataTask *task, id responseObject) {
             self.tweets = (NSMutableArray *)responseObject;
             [self didLoadTweetsWithError:nil];
         }
         failure:^(NSURLSessionDataTask *task, NSError *error) {
             [self didLoadTweetsWithError:error];
         }];
#else
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:twitterAPIURL];
    manager.requestSerializer = [[AppDelegate sharedDelegate] requestSerializer];
    [manager GET:@"statuses/home_timeline.json"
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

    cell.tweetLabel.text = self.tweets[indexPath.row];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.tweetCell.frame.size.height;
}

@end
