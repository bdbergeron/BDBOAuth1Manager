//
//  AppDelegate.m
//  BDBOAuth1ManagerDemo
//
//  Created by Bradley Bergeron on 11/10/2013.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import "AppDelegate.h"
#import "TweetsViewController.h"

#import "NSURL+BDBOAuth1Manager.h"


#pragma mark -
@interface AppDelegate ()

@property (nonatomic) TweetsViewController *tweetsVC;

#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000) || (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= 1090)
@property (nonatomic, readwrite) BDBOAuth1SessionManager *networkManager;
#else
@property (nonatomic, readwrite) BDBOAuth1RequestOperationManager *networkManager;
#endif

@end


#pragma mark -
@implementation AppDelegate

static AppDelegate *_sharedDelegate = nil;

#pragma mark Initialization
- (id)init
{
    self = [super init];
    if (self)
    {
        self.tweetsVC = [[TweetsViewController alloc] initWithNibName:nil bundle:nil];
        
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000) || (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= 1090)
        self.networkManager = [[BDBOAuth1SessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.twitter.com/1.1/"]
                                                                   consumerKey:@"wrou647dSAp3OinHmsVKYw"
                                                                consumerSecret:@"Y1H5mOBxHMIDkW6KMeiJAd4G0VFTSA2GdVKq5SEdB4"];

#else
        self.networkManager = [[BDBOAuth1RequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.twitter.com/1.1/"]
                                                                            consumerKey:@"wrou647dSAp3OinHmsVKYw"
                                                                         consumerSecret:@"Y1H5mOBxHMIDkW6KMeiJAd4G0VFTSA2GdVKq5SEdB4"];
#endif

        _sharedDelegate = self;
    }
    return self;
}

+ (instancetype)sharedDelegate
{
    return _sharedDelegate;
}

#pragma mark OAuth Authorization
- (void)authorize
{
    [self.networkManager fetchRequestTokenWithPath:@"/oauth/request_token"
                                            method:@"POST"
                                       callbackURL:[NSURL URLWithString:@"bdboauth://request"]
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

- (void)deauthorizeWithCompletion:(void (^)(void))completion
{
    [self.networkManager deauthorize];
    if (completion)
        completion();
}

#pragma mark Application Lifecyle
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:self.tweetsVC];
    [self.window makeKeyAndVisible];

    if (!self.networkManager.isAuthorized)
        [self authorize];

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([url.scheme isEqualToString:@"bdboauth"])
    {
        if ([url.host isEqualToString:@"request"])
        {
            NSDictionary *parameters = [url dictionaryFromQueryString];
            if (parameters[@"oauth_token"] && parameters[@"oauth_verifier"])
                [self.networkManager fetchAccessTokenWithPath:@"/oauth/access_token"
                                                       method:@"POST"
                                                 requestToken:[BDBOAuthToken tokenWithQueryString:url.query]
                                                      success:^(BDBOAuthToken *accessToken) {
                                                          [self.networkManager.requestSerializer saveAccessToken:accessToken];
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
        return YES;
    }
    return NO;
}

@end
