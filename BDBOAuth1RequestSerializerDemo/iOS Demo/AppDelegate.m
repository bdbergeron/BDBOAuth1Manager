//
//  AppDelegate.m
//
//  Created by Bradley Bergeron on 11/10/2013.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import "AppDelegate.h"
#import "BDBOAuth1RequestSerializer.h"
#import "TweetsViewController.h"


#pragma mark -
@interface AppDelegate ()

@property (nonatomic, readwrite) AFHTTPRequestSerializer *requestSerializer;

@end


#pragma mark -
@implementation AppDelegate

static AppDelegate *_sharedDelegate;

- (id)init
{
    self = [super init];
    if (self)
        _sharedDelegate = self;
    return self;
}

+ (instancetype)sharedDelegate
{
    return _sharedDelegate;
}

#pragma mark Application Lifecyle
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.requestSerializer = [BDBOAuth1RequestSerializer serializerWithConsumerKey:@"wrou647dSAp3OinHmsVKYw"
                                                                    consumerSecret:@"Y1H5mOBxHMIDkW6KMeiJAd4G0VFTSA2GdVKq5SEdB4"];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:[[TweetsViewController alloc] init]];
    self.window.rootViewController = navVC;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
