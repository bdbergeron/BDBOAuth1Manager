# BDBOAuth1Manager

BDBOAuth1Manager is an AFNetworking 2.0-compatible replacement for AFOAuth1Client.

## Usage

BDBOAuth1Manager consists of three core classes: `BDBOAuth1RequestSerializer`, `BDBOAuth1RequestOperationManger`, and `BDBOAuth1SessionManager`. Below I will provide a quick overview of each, but to really see how the three classes work together, take a look at the included demo apps. One is a simple Twitter client and the other a simple Flickr photo gallery, but they show how to get started using BDBOAuth1Manager in your projects.

### BDBOAuth1RequestOperationManger

`BDBOAuth1RequestOperationManger` is a subclass of `AFHTTPRequestOperationManager` that provides methods to facilitate the OAuth 1 authentication flow.

```objective-c
@property (nonatomic, strong) BDBOAuth1RequestSerializer *requestSerializer;
@property (nonatomic, assign, readonly, getter = isAuthorized) BOOL authorized;

#pragma mark Initialization
- (instancetype)initWithBaseURL:(NSURL *)url
                    consumerKey:(NSString *)key
                 consumerSecret:(NSString *)secret;

#pragma mark Deauthorize
- (BOOL)deauthorize;

#pragma mark Authorization Flow
- (void)fetchRequestTokenWithPath:(NSString *)requestPath
                           method:(NSString *)method
                      callbackURL:(NSURL *)callbackURL
                            scope:(NSString *)scope
                          success:(void (^)(BDBOAuthToken *requestToken))success
                          failure:(void (^)(NSError *error))failure;

- (void)fetchAccessTokenWithPath:(NSString *)accessPath
                          method:(NSString *)method
                    requestToken:(BDBOAuthToken *)requestToken
                         success:(void (^)(BDBOAuthToken *accessToken))success
                         failure:(void (^)(NSError *error))failure;
```

### BDBOAuth1SessionManager

`BDBOAuth1SessionManager` is a subclass of `AFHTTPSessionManager` that implements all the same methods and properties as `BDBOAuth1RequestOperationManger`, described above.

If you're targeting either iOS 6 or OS X 10.8, you must use `BDBOAuth1RequestOperationManger`, as the underlying `NSURLSession` that is used by `AFHTTPSessionManager` is a new addition to the iOS and OS X networking frameworks for iOS 7 and OS X 10.9.

### BDBOAuth1RequestSerializer

`BDBOAuth1RequestSerializer` is a subclass of `AFHTTPRequestSerializer` that handles all the networking requests performed by `BDBOAuth1RequestOperationManger` and `BDBOAuth1SessionManager`. Both classes automatically handle the creation of this serializer, so you should never have to instantiate it on your own.

`BDBOAuth1RequestSerializer` also has built-in support for storing and retrieving access tokens to/from the user's keychain, utilizing the service name to differentiate tokens. `BDBOAuth1RequestOperationManger` and `BDBOAuth1SessionManager` automatically set the service name to baseURL.host (e.g. api.twitter.com) when they are instantiated.

```objective-c
@property (nonatomic, copy, readonly) BDBOAuthToken *accessToken;

#pragma mark Initialization
+ (instancetype)serializerForService:(NSString *)service
                     withConsumerKey:(NSString *)key
                      consumerSecret:(NSString *)secret;
- (id)initWithService:(NSString *)service
          consumerKey:(NSString *)key
       consumerSecret:(NSString *)secret;

#pragma mark OAuth
- (NSDictionary *)OAuthParameters;

#pragma mark AccessToken
- (BOOL)saveAccessToken:(BDBOAuthToken *)accessToken;
- (BOOL)removeAccessToken;
```

## Authentication Flow

The first step in performing the OAuth handshake is getting an OAuth request token for your application. This can be done with the `fetchRequestTokenWithPath:method:callbackURL:scope:success:failure:` method.

```objective-c
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
                                       }];
``` 

### Creating a URL Type for OAuth Callbacks

When calling `fetchRequestTokenWithPath:method:callbackURL:scope:success:failure:`, you must provide a unique callback URL whose scheme corresponds to a URL type you've added to your project target. This allows the OAuth provider to return the user to your app after the user has authorized it. For example, if I add a URL type to my project with the scheme `bdboauth`, my application would then respond to all URL requests that begin with `bdboauth:`. If I pass `bdboauth://request` as the callback URL, the OAuth provider would call that URL and my application would resume.

![URL Types Screenshot](https://dl.dropboxusercontent.com/u/6225/GitHub/BDBOAuth1Manager/urltypes.png)

### Responding to OAuth Callbacks

In order to respond to your application's URL scheme being called, you must implement the `-application:openURL:sourceApplication:annotation` method within your application delegate. You can do something like this:

```objective-c
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
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
                                                      }];
        }
        return YES;
    }
    return NO;
}
```

## Credits

BDBOAuth1Manager was created by [Bradley David Bergeron](http://www.bradbergeron.com) and influenced by [AFOAuth1Client](https://github.com/AFNetworking/AFOAuth1Client). Both [AFNetworking](https://github.com/AFNetworking/AFNetworking) and [AFOAuth1Client](https://github.com/AFNetworking/AFOAuth1Client) are the awesome work of [Mattt Thompson](https://github.com/mattt).

