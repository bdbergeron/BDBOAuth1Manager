//
//  AppDelegate.m
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
#import "TweetsViewController.h"

#import "NSDictionary+BDBOAuth1Manager.h"

#pragma mark -
@interface AppDelegate ()

@property (nonatomic) TweetsViewController *tweetsVC;

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
@property (nonatomic, readwrite) BDBOAuth1SessionManager *networkManager;
#else
@property (nonatomic, readwrite) BDBOAuth1RequestOperationManager *networkManager;
#endif

@end

#pragma mark -
@implementation AppDelegate

static AppDelegate * _sharedDelegate = nil;

#pragma mark Initialization
- (id)init {
    self = [super init];

    if (self) {
        self.tweetsVC = [[TweetsViewController alloc] initWithNibName:nil bundle:nil];

        NSURL *apiURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/"];
        NSString *consumerKey = @"wrou647dSAp3OinHmsVKYw";
        NSString *consumerSecret = @"Y1H5mOBxHMIDkW6KMeiJAd4G0VFTSA2GdVKq5SEdB4";
        
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
        self.networkManager = [[BDBOAuth1SessionManager alloc] initWithBaseURL:apiURL consumerKey:consumerKey consumerSecret:consumerSecret];
#else
        self.networkManager = [[BDBOAuth1RequestOperationManager alloc] initWithBaseURL:apiURL consumerKey:consumerKey consumerSecret:consumerSecret];
#endif

        _sharedDelegate = self;
    }

    return self;
}

+ (instancetype)sharedDelegate {
    return _sharedDelegate;
}

#pragma mark OAuth Authorization
- (void)authorize {
    [self.networkManager fetchRequestTokenWithPath:@"/oauth/request_token"
                                            method:@"POST"
                                       callbackURL:[NSURL URLWithString:@"bdbtwitter://request"]
                                             scope:nil
                                           success:^(BDBOAuthToken *requestToken) {
                                               NSString *authURL = [NSString stringWithFormat:@"https://api.twitter.com/oauth/authorize?oauth_token=%@", requestToken.token];
                                               [[UIApplication sharedApplication] openURL:[NSURL URLWithString:authURL]];
                                           }
                                           failure:^(NSError *error) {
                                               NSLog(@"Error: %@", error.localizedDescription);
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   [[[UIAlertView alloc] initWithTitle:@"Error"
                                                                               message:@"Could not acquire OAuth request token. Please try again later."
                                                                              delegate:self
                                                                     cancelButtonTitle:@"Dismiss"
                                                                     otherButtonTitles:nil] show];
                                               });
                                           }];
}

- (void)deauthorizeWithCompletion:(void (^)(void))completion {
    [self.networkManager deauthorize];

    if (completion) {
        completion();
    }
}

#pragma mark Application Lifecyle
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:self.tweetsVC];
    [self.window makeKeyAndVisible];

    if (!self.networkManager.isAuthorized) {
        [self authorize];
    }

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([url.scheme isEqualToString:@"bdbtwitter"]) {
        if ([url.host isEqualToString:@"request"]) {
            NSDictionary *parameters = [NSDictionary dictionaryFromQueryString:url.query];

            if (parameters[@"oauth_token"] && parameters[@"oauth_verifier"]) {
                [self.networkManager fetchAccessTokenWithPath:@"/oauth/access_token"
                                                       method:@"POST"
                                                 requestToken:[BDBOAuthToken tokenWithQueryString:url.query]
                                                      success:^(BDBOAuthToken *accessToken) {
                                                          [self.tweetsVC refreshFeed];
                                                          dispatch_async(dispatch_get_main_queue(), ^{
                                                              self.tweetsVC.navigationItem.rightBarButtonItem.title = @"Log Out";
                                                          });
                                                      }
                                                      failure:^(NSError *error) {
                                                          NSLog(@"Error: %@", error.localizedDescription);
                                                          dispatch_async(dispatch_get_main_queue(), ^{
                                                              [[[UIAlertView alloc] initWithTitle:@"Error"
                                                                                          message:@"Could not acquire OAuth access token. Please try again later."
                                                                                         delegate:self
                                                                                cancelButtonTitle:@"Dismiss"
                                                                                otherButtonTitles:nil] show];
                                                          });
                                                      }];
            }
        }

        return YES;
    }
    
    return NO;
}

@end
