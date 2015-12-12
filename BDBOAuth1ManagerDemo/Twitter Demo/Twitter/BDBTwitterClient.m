//
//  BDBTwitterClient.m
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

#import "BDBOAuth1SessionManager.h"
#import "BDBTweet.h"
#import "BDBTwitterClient.h"

#import "NSDictionary+BDBOAuth1Manager.h"


// Exported
NSString * const BDBTwitterClientErrorDomain = @"BDBTwitterClientErrorDomain";

NSString * const BDBTwitterClientDidLogInNotification  = @"BDBTwitterClientDidLogInNotification";
NSString * const BDBTwitterClientDidLogOutNotification = @"BDBTwitterClientDidLogOutNotification";

// Internal
static NSString * const kBDBTwitterClientAPIURL   = @"https://api.twitter.com/1.1/";

static NSString * const kBDBTwitterClientOAuthAuthorizeURL     = @"https://api.twitter.com/oauth/authorize";
static NSString * const kBDBTwitterClientOAuthCallbackURL      = @"bdboauth1demo-twitter://authorize";
static NSString * const kBDBTwitterClientOAuthRequestTokenPath = @"https://api.twitter.com/oauth/request_token";
static NSString * const kBDBTwitterClientOAuthAccessTokenPath  = @"https://api.twitter.com/oauth/access_token";


#pragma mark -
@interface BDBTwitterClient ()

@property (nonatomic) BDBOAuth1SessionManager *networkManager;

- (id)initWithConsumerKey:(NSString *)key sceret:(NSString *)secret;

@end

#pragma mark -
@implementation BDBTwitterClient

#pragma mark Initialization
static BDBTwitterClient *_sharedClient = nil;

+ (instancetype)createWithConsumerKey:(NSString *)key secret:(NSString *)secret {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[[self class] alloc] initWithConsumerKey:key sceret:secret];
    });

    return _sharedClient;
}

- (id)initWithConsumerKey:(NSString *)key sceret:(NSString *)secret {
    self = [super init];

    if (self) {
        NSURL *baseURL = [NSURL URLWithString:kBDBTwitterClientAPIURL];
        _networkManager = [[BDBOAuth1SessionManager alloc] initWithBaseURL:baseURL consumerKey:key consumerSecret:secret];
    }

    return self;
}

+ (instancetype)sharedClient {
    NSAssert(_sharedClient, @"BDBTwitterClient not initialized. [BDBTwitterClient createWithConsumerKey:secret:] must be called first.");

    return _sharedClient;
}

#pragma mark Authorization
+ (BOOL)isAuthorizationCallbackURL:(NSURL *)url {
    NSURL *callbackURL = [NSURL URLWithString:kBDBTwitterClientOAuthCallbackURL];

    return _sharedClient && [url.scheme isEqualToString:callbackURL.scheme] && [url.host isEqualToString:callbackURL.host];
}

- (BOOL)isAuthorized {
    return self.networkManager.authorized;
}

- (void)authorize {
    [self.networkManager fetchRequestTokenWithPath:kBDBTwitterClientOAuthRequestTokenPath
                                            method:@"POST"
                                       callbackURL:[NSURL URLWithString:kBDBTwitterClientOAuthCallbackURL]
                                             scope:nil
                                           success:^(BDBOAuth1Credential *requestToken) {
                                               // Perform Authorization via MobileSafari
                                               NSString *authURLString = [kBDBTwitterClientOAuthAuthorizeURL stringByAppendingFormat:@"?oauth_token=%@", requestToken.token];

                                               [[UIApplication sharedApplication] openURL:[NSURL URLWithString:authURLString]];
                                           }
                                           failure:^(NSError *error) {
                                               NSLog(@"Error: %@", error.localizedDescription);

                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                               message:NSLocalizedString(@"Could not acquire OAuth request token. Please try again later.", nil)
                                                                              delegate:self
                                                                     cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                                                                     otherButtonTitles:nil] show];
                                               });
                                           }];
}

- (BOOL)handleAuthorizationCallbackURL:(NSURL *)url {
    NSDictionary *parameters = [NSDictionary bdb_dictionaryFromQueryString:url.query];

    if (parameters[BDBOAuth1OAuthTokenParameter] && parameters[BDBOAuth1OAuthVerifierParameter]) {
        [self.networkManager fetchAccessTokenWithPath:kBDBTwitterClientOAuthAccessTokenPath
                                               method:@"POST"
                                         requestToken:[BDBOAuth1Credential credentialWithQueryString:url.query]
                                              success:^(BDBOAuth1Credential *accessToken) {
                                                  [[NSNotificationCenter defaultCenter] postNotificationName:BDBTwitterClientDidLogInNotification
                                                                                                      object:self
                                                                                                    userInfo:accessToken.userInfo];
                                              }
                                              failure:^(NSError *error) {
                                                  NSLog(@"Error: %@", error.localizedDescription);

                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                                  message:NSLocalizedString(@"Could not acquire OAuth access token. Please try again later.", nil)
                                                                                 delegate:self
                                                                        cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                                                                        otherButtonTitles:nil] show];
                                                  });
                                              }];

        return YES;
    }
    
    return NO;
}

- (void)deauthorize {
    [self.networkManager deauthorize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BDBTwitterClientDidLogOutNotification object:self];
}

#pragma mark Tweets
- (void)loadTimelineWithCompletion:(void (^)(NSArray *, NSError *))completion {
    static NSString *timelinePath = @"statuses/home_timeline.json?count=100";

    [self.networkManager GET:timelinePath
                  parameters:nil
                    progress:nil
                     success:^(NSURLSessionDataTask *task, id responseObject) {
                         [self parseTweetsFromAPIResponse:responseObject completion:completion];
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         completion(nil, error);
                     }];
}

- (void)parseTweetsFromAPIResponse:(id)responseObject completion:(void (^)(NSArray *, NSError *))completion {
    if (![responseObject isKindOfClass:[NSArray class]]) {
        NSError *error = [NSError errorWithDomain:BDBTwitterClientErrorDomain
                                             code:1000
                                         userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Unexpected response received from Twitter API.", nil)}];

        return completion(nil, error);
    }

    NSArray *response = responseObject;

    NSMutableArray *tweets = [NSMutableArray array];

    for (NSDictionary *tweetInfo in response) {
        BDBTweet *tweet = [[BDBTweet alloc] initWithDictionary:tweetInfo];
        [tweets addObject:tweet];
    }

    completion(tweets, nil);
}

@end
