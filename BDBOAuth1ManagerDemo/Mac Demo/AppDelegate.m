//
//  AppDelegate.m
//  BDBOAuth1RequestSerializerDemo
//
//  Created by Bradley Bergeron on 11/10/2013.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import "AppDelegate.h"


#pragma mark -
@interface AppDelegate ()

#ifdef __MAC_10_10
@property (nonatomic, readwrite) BDBOAuth1SessionManager *networkManager;
#else
@property (nonatomic, readwrite) BDBOAuth1RequestOperationManager *networkManager;
#endif

@property (nonatomic, assign, readwrite, getter = isAuthorized) BOOL authorized;

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
        self.networkManager = [[BDBOAuth1RequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.twitter.com/1.1/"]
                                                                            consumerKey:@"wrou647dSAp3OinHmsVKYw"
                                                                         consumerSecret:@"Y1H5mOBxHMIDkW6KMeiJAd4G0VFTSA2GdVKq5SEdB4"];

        _sharedDelegate = self;
    }
    return self;
}

+ (instancetype)sharedDelegate
{
    return _sharedDelegate;
}

#pragma mark OAuth Authorization
- (BOOL)isAuthorized
{
    return self.networkManager.requestSerializer.accessToken != nil;
}

- (void)authorize
{
    [self.networkManager fetchRequestTokenWithPath:@"/oauth/request_token"
                                            method:@"POST"
                                       callbackURL:[NSURL URLWithString:@"bdboauth://request"]
                                             scope:nil
                                           success:^(BDBOAuthToken *requestToken, id responseObject) {
                                               NSString *authURL = [NSString stringWithFormat:@"https://api.twitter.com/oauth/authorize?oauth_token=%@", requestToken.token];
                                               [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:authURL]];
                                           }
                                           failure:^(NSError *error) {
                                               NSLog(@"Error: %@", error.localizedDescription);
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   [[NSAlert alertWithMessageText:@"Could not acquire OAuth request token. Please try again."
                                                                    defaultButton:@"Dismiss"
                                                                  alternateButton:nil
                                                                      otherButton:nil
                                                            informativeTextWithFormat:nil] runModal];
                                               });
                                           }];
}

#pragma mark Application Lifecycle
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

}

@end
