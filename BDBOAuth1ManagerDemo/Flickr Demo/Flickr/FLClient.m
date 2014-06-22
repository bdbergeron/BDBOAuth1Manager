//
//  FLClient.m
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

#import "FLClient.h"

#import "NSDictionary+BDBOAuth1Manager.h"


// Exported
NSString * const FLClientErrorDomain = @"FLClientErrorDomain";

NSString * const FLClientDidLogInNotification  = @"FLClientDidLogInNotification";
NSString * const FLClientDidLogOutNotification = @"FLClientDidLogOutNotification";

// Internal
static NSString * const kFLClientAPIURL   = @"https://api.flickr.com/services/";

static NSString * const kFLClientOAuthAuthorizeURL     = @"https://www.flickr.com/services/oauth/authorize";
static NSString * const kFLClientOAuthCallbackURL      = @"bdbflclient://authorize";
static NSString * const kFLClientOAuthRequestTokenPath = @"oauth/request_token";
static NSString * const kFLClientOAuthAccessTokenPath  = @"oauth/access_token";


#pragma mark -
@interface FLClient ()

@property (nonatomic, copy) NSString *apiKey;

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
@property (nonatomic) BDBOAuth1SessionManager *networkManager;
#else
@property (nonatomic) BDBOAuth1RequestOperationManager *networkManager;
#endif

- (id)initWithAPIKey:(NSString *)apiKey sceret:(NSString *)secret;

- (NSDictionary *)defaultRequestParameters;

@end

#pragma mark -
@implementation FLClient

#pragma mark Initialization
static FLClient *_sharedClient = nil;

+ (instancetype)createWithAPIKey:(NSString *)apiKey secret:(NSString *)secret {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[[self class] alloc] initWithAPIKey:apiKey sceret:secret];
    });

    return _sharedClient;
}

- (id)initWithAPIKey:(NSString *)apiKey sceret:(NSString *)secret {
    self = [super init];

    if (self) {
        _apiKey = [apiKey copy];

        NSURL *baseURL = [NSURL URLWithString:kFLClientAPIURL];

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
        _networkManager = [[BDBOAuth1SessionManager alloc] initWithBaseURL:baseURL consumerKey:apiKey consumerSecret:secret];
#else
        _networkManager = [[BDBOAuth1RequestOperationManager alloc] initWithBaseURL:baseURL consumerKey:apiKey consumerSecret:secret];
#endif
    }

    return self;
}

+ (instancetype)sharedClient {
    NSAssert(_sharedClient, @"FLClient not initialized. [FLClient createWithAPIKey:secret:] must be called first.");

    return _sharedClient;
}

#pragma mark Authorization
+ (BOOL)isAuthorizationCallbackURL:(NSURL *)url {
    NSURL *callbackURL = [NSURL URLWithString:kFLClientOAuthCallbackURL];

    return _sharedClient && [url.scheme isEqualToString:callbackURL.scheme] && [url.host isEqualToString:callbackURL.host];
}

- (BOOL)isAuthorized {
    return self.networkManager.authorized;
}

- (void)authorize {
    [self.networkManager fetchRequestTokenWithPath:kFLClientOAuthRequestTokenPath
                                            method:@"POST"
                                       callbackURL:[NSURL URLWithString:kFLClientOAuthCallbackURL]
                                             scope:nil
                                           success:^(BDBOAuthToken *requestToken) {
                                               // Perform Authorization via MobileSafari
                                               NSString *authURLString = [kFLClientOAuthAuthorizeURL stringByAppendingFormat:@"?oauth_token=%@", requestToken.token];

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
    NSDictionary *parameters = [NSDictionary dictionaryFromQueryString:url.query];

    if (parameters[BDBOAuth1OAuthTokenParameter] && parameters[BDBOAuth1OAuthVerifierParameter]) {
        [self.networkManager fetchAccessTokenWithPath:kFLClientOAuthAccessTokenPath
                                               method:@"POST"
                                         requestToken:[BDBOAuthToken tokenWithQueryString:url.query]
                                              success:^(BDBOAuthToken *accessToken) {
                                                  [[NSNotificationCenter defaultCenter] postNotificationName:FLClientDidLogInNotification
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

    [[NSNotificationCenter defaultCenter] postNotificationName:FLClientDidLogOutNotification object:self];
}

#pragma mark Helpers
- (NSDictionary *)defaultRequestParameters {
    return @{@"api_key":        self.apiKey,
             @"format":         @"json",
             @"nojsoncallback": @(1)};
}

#pragma mark Photosets
- (void)getPhotosetsWithCompletion:(void (^)(NSSet *, NSError *))completion {
    NSAssert(self.apiKey, @"API key not set.");

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self defaultRequestParameters]];
    params[@"method"] = @"flickr.photosets.getList";

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    [self.networkManager GET:@"rest" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        [self parsePhotosetsFromAPIResponseObject:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil, error);
    }];
#else
    [self.networkManager GET:@"rest" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self parsePhotosetsFromAPIResponseObject:responseObject completion:completion];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
#endif
}

- (void)parsePhotosetsFromAPIResponseObject:(id)responseObject completion:(void (^)(NSSet *, NSError *))completion {
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSError *error = [NSError errorWithDomain:FLClientErrorDomain
                                             code:1000
                                         userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Unexpected response received from Flickr API.", nil)}];

        return completion(nil, error);
    }

    NSDictionary *response = responseObject;

    if (![response[@"stat"] isEqualToString:@"ok"]) {
        NSError *error = [NSError errorWithDomain:FLClientErrorDomain
                                             code:1100
                                         userInfo:@{NSLocalizedDescriptionKey:response[@"message"]}];

        return completion(nil, error);
    }

    response = response[@"photosets"];
    NSMutableSet *photosets = [NSMutableSet set];

    for (NSDictionary *setInfo in response[@"photoset"]) {
        FLPhotoset *set = [[FLPhotoset alloc] initWithDictionary:setInfo];
        [photosets addObject:set];
    }

    completion(photosets, nil);
}

#pragma mark Photos
- (void)getPhotosInPhotoset:(FLPhotoset *)photoset completion:(void (^)(NSArray *, NSError *))completion {
    NSAssert(self.apiKey, @"API key not set.");

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self defaultRequestParameters]];
    params[@"method"] = @"flickr.photosets.getPhotos";
    params[@"photoset_id"] = photoset.setId;
    params[@"extras"] = @"url_t, url_o, description";

    NSString *path = @"rest";

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    [self.networkManager GET:path parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        [self parsePhotosFromAPIResponseObject:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil, error);
    }];
#else
    [self.networkManager GET:path parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self parsePhotosFromAPIResponseObject:responseObject completion:completion];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
#endif
}

- (void)parsePhotosFromAPIResponseObject:(id)responseObject completion:(void (^)(NSArray *, NSError *))completion {
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSError *error = [NSError errorWithDomain:FLClientErrorDomain
                                             code:1000
                                         userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Unexpected response received from Flickr API.", nil)}];

        return completion(nil, error);
    }

    NSDictionary *response = responseObject;

    if (![response[@"stat"] isEqualToString:@"ok"]) {
        NSError *error = [NSError errorWithDomain:FLClientErrorDomain
                                             code:1100
                                         userInfo:@{NSLocalizedDescriptionKey:response[@"message"]}];

        return completion(nil, error);
    }

    response = response[@"photoset"];
    NSMutableArray *photos = [NSMutableArray array];

    for (NSDictionary *photoInfo in response[@"photo"]) {
        FLPhoto *photo = [[FLPhoto alloc] initWithDictionary:photoInfo];
        [photos addObject:photo];
    }

    completion(photos, nil);
}

@end
