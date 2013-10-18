# BDBOAuth1Manager

BDBOAuth1Manager is an AFNetworking 2.0-compatible replacement for AFOAuth1Client.

## Usage

BDBOAuth1Manager consists of three core classes: `BDBOAuth1RequestSerializer`, `BDBOAuth1RequestOperationManger`, and `BDBOAuth1SessionManager`. Below I will provide a quick overview of each, but to really see how the three classes work together, take a look at the demo app. It's a simple Twitter client, but it shows how to get started using BDBOAuth1Manager in your projects.

### BDBOAuth1RequestOperationManger

`BDBOAuth1RequestOperationManger` is a subclass of `AFHTTPRequestOperationManager` that provides methods to facilitate the OAuth 1 authentication flow.

```objective-c
#pragma mark Initialization
- (instancetype)initWithBaseURL:(NSURL *)url consumerKey:(NSString *)key consumerSecret:(NSString *)secret;

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
+ (instancetype)serializerForService:(NSString *)service withConsumerKey:(NSString *)key consumerSecret:(NSString *)secret;
- (id)initWithService:(NSString *)service consumerKey:(NSString *)key consumerSecret:(NSString *)secret;

#pragma mark OAuth
- (NSDictionary *)OAuthParameters;

#pragma mark AccessToken
- (BOOL)saveAccessToken:(BDBOAuthToken *)accessToken;
- (BOOL)removeAccessToken;
```

## Credits

BDBOAuth1Manager was created by [Bradley David Bergeron](http://www.bradbergeron.com) and influenced by [AFOAuth1Client](https://github.com/AFNetworking/AFOAuth1Client). Both [AFNetworking](https://github.com/AFNetworking/AFNetworking) and [AFOAuth1Client](https://github.com/AFNetworking/AFOAuth1Client) are the awesome work of [Mattt Thompson](https://github.com/mattt).

