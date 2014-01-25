//
//  BDBOAuth1SessionManager.m
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
    self.requestSerializer.requestToken = nil;

    AFHTTPResponseSerializer *defaultSerializer = self.responseSerializer;
    self.responseSerializer = [AFHTTPResponseSerializer serializer];

    NSMutableDictionary *parameters = [[self.requestSerializer OAuthParameters] mutableCopy];
    parameters[@"oauth_callback"] = [callbackURL absoluteString];
    if (scope && !self.requestSerializer.accessToken)
        parameters[@"scope"] = scope;

    NSString *URLString = [[NSURL URLWithString:requestPath relativeToURL:self.baseURL] absoluteString];
    NSError *error;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:URLString parameters:parameters error:&error];

    if (error)
    {
        failure(error);
        return;
    }

    NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
        self.responseSerializer = defaultSerializer;
        if (!error)
        {
            BDBOAuthToken *requestToken = [BDBOAuthToken tokenWithQueryString:[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]];
            self.requestSerializer.requestToken = requestToken;
            if (success)
                success(requestToken);
        }
        else
            if (failure)
                failure(error);
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
        NSError *error;
        NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:URLString parameters:parameters error:&error];

        if (error)
        {
            failure(error);
            return;
        }

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
        NSError *error = [[NSError alloc] initWithDomain:BDBOAuth1ErrorDomain
                                                    code:NSURLErrorBadServerResponse
                                                userInfo:@{NSLocalizedFailureReasonErrorKey:@"Invalid OAuth response received from server."}];
        failure(error);
    }
}

@end

#endif
