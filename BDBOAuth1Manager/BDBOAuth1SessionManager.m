//
//  BDBOAuth1SessionManager.m
//
//  Created by Bradley Bergeron on 10/17/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import "AFURLConnectionOperation.h"
#import "BDBOAuth1SessionManager.h"

#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000) || (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= 1090)

#pragma mark -
@interface BDBOAuth1SessionManager ()

@end


#pragma mark -
@implementation BDBOAuth1SessionManager

#pragma mark Initialization
- (instancetype)initWithBaseURL:(NSURL *)url consumerKey:(NSString *)key consumerSecret:(NSString *)secret
{
    self = [super initWithBaseURL:url];
    if (self)
    {
        self.requestSerializer  = [BDBOAuth1RequestSerializer serializerForService:url.host withConsumerKey:key consumerSecret:secret];
    }
    return self;
}

#pragma mark Access Token
- (BOOL)isAuthorized
{
    return (self.requestSerializer.accessToken && !self.requestSerializer.accessToken.expired);
}

- (BOOL)deauthorize
{
    return [self.requestSerializer removeAccessToken];
}

#pragma mark Authorization Flow
- (void)fetchRequestTokenWithPath:(NSString *)requestPath
                           method:(NSString *)method
                      callbackURL:(NSURL *)callbackURL
                            scope:(NSString *)scope
                          success:(void (^)(BDBOAuthToken *requestToken))success
                          failure:(void (^)(NSError *error))failure
{
    AFHTTPResponseSerializer *defaultSerializer = self.responseSerializer;
    self.responseSerializer = [AFHTTPResponseSerializer serializer];

    NSMutableDictionary *parameters = [[self.requestSerializer OAuthParameters] mutableCopy];
    parameters[@"oauth_callback"] = [callbackURL absoluteString];
    if (scope && !self.requestSerializer.accessToken)
        parameters[@"scope"] = scope;

    NSString *URLString = [[NSURL URLWithString:requestPath relativeToURL:self.baseURL] absoluteString];
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:URLString parameters:parameters];

    NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
        self.responseSerializer = defaultSerializer;
        BDBOAuthToken *requestToken = [BDBOAuthToken tokenWithQueryString:[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]];
        self.requestSerializer.requestToken = requestToken;
        if (error && failure)
            failure(error);
        else if (success)
            success(requestToken);
    }];

    [task resume];
}

- (void)fetchAccessTokenWithPath:(NSString *)accessPath
                          method:(NSString *)method
                    requestToken:(BDBOAuthToken *)requestToken
                         success:(void (^)(BDBOAuthToken *accessToken))success
                         failure:(void (^)(NSError *error))failure
{
    if (requestToken.token && requestToken.verifier)
    {
        AFHTTPResponseSerializer *defaultSerializer = self.responseSerializer;
        self.responseSerializer = [AFHTTPResponseSerializer serializer];

        NSMutableDictionary *parameters = [[self.requestSerializer OAuthParameters] mutableCopy];
        parameters[@"oauth_token"]    = requestToken.token;
        parameters[@"oauth_verifier"] = requestToken.verifier;

        NSString *URLString = [[NSURL URLWithString:accessPath relativeToURL:self.baseURL] absoluteString];
        NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:URLString parameters:parameters];

        NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
            self.responseSerializer = defaultSerializer;
            self.requestSerializer.requestToken = nil;
            if (!error)
            {
                BDBOAuthToken *accessToken = [BDBOAuthToken tokenWithQueryString:[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]];
                [self.requestSerializer saveAccessToken:accessToken];
                if (success)
                    success(accessToken);
            }
            else
                if (failure)
                    failure(error);
        }];

        [task resume];
    }
    else
    {
        NSError *error = [[NSError alloc] initWithDomain:AFNetworkingErrorDomain
                                                    code:NSURLErrorBadServerResponse
                                                userInfo:@{NSLocalizedFailureReasonErrorKey:@"Invalid OAuth response received from server."}];
        failure(error);
    }
}

@end

#endif
