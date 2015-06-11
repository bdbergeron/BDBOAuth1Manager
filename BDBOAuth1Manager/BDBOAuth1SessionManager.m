//
//  BDBOAuth1SessionManager.m
//
//  Copyright (c) 2013-2015 Bradley David Bergeron
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

#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)

#pragma mark -
@interface BDBOAuth1SessionManager ()

@end


#pragma mark -
@implementation BDBOAuth1SessionManager

@dynamic requestSerializer;

#pragma mark Initialization
- (instancetype)initWithBaseURL:(NSURL *)baseURL
                    consumerKey:(NSString *)consumerKey
                 consumerSecret:(NSString *)consumerSecret {
    self = [super initWithBaseURL:baseURL];

    if (self) {
        self.requestSerializer  = [BDBOAuth1RequestSerializer serializerForService:baseURL.host
                                                                   withConsumerKey:consumerKey
                                                                    consumerSecret:consumerSecret];
    }

    return self;
}

#pragma mark Authorization Status
- (BOOL)isAuthorized {
    return (self.requestSerializer.accessToken && !self.requestSerializer.accessToken.expired);
}

- (BOOL)deauthorize {
    return [self.requestSerializer removeAccessToken];
}

#pragma mark OAuth Handshake
- (void)fetchRequestTokenWithPath:(NSString *)requestPath
                           method:(NSString *)method
                      callbackURL:(NSURL *)callbackURL
                            scope:(NSString *)scope
                          success:(void (^)(BDBOAuth1Credential *requestToken))success
                          failure:(void (^)(NSError *error))failure {
    self.requestSerializer.requestToken = nil;

    AFHTTPResponseSerializer *defaultSerializer = self.responseSerializer;
    self.responseSerializer = [AFHTTPResponseSerializer serializer];

    NSMutableDictionary *parameters = [[self.requestSerializer OAuthParameters] mutableCopy];
    parameters[BDBOAuth1OAuthCallbackParameter] = [callbackURL absoluteString];

    if (scope && !self.requestSerializer.accessToken) {
        parameters[@"scope"] = scope;
    }

    NSString *URLString = [[NSURL URLWithString:requestPath relativeToURL:self.baseURL] absoluteString];
    NSError *error;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:URLString parameters:parameters error:&error];

    if (error) {
        failure(error);

        return;
    }

    void (^completionBlock)(NSURLResponse * __unused, id, NSError *) = ^(NSURLResponse * __unused response, id responseObject, NSError *completionError) {
        self.responseSerializer = defaultSerializer;

        if (completionError) {
            failure(completionError);

            return;
        }

        BDBOAuth1Credential *requestToken = [BDBOAuth1Credential credentialWithQueryString:[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]];
        self.requestSerializer.requestToken = requestToken;

        success(requestToken);
    };

    NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:completionBlock];
    [task resume];
}

- (void)fetchAccessTokenWithPath:(NSString *)accessPath
                          method:(NSString *)method
                    requestToken:(BDBOAuth1Credential *)requestToken
                         success:(void (^)(BDBOAuth1Credential *accessToken))success
                         failure:(void (^)(NSError *error))failure {
    if (!requestToken.token || !requestToken.verifier) {
        NSError *error = [[NSError alloc] initWithDomain:BDBOAuth1ErrorDomain
                                                    code:NSURLErrorBadServerResponse
                                                userInfo:@{NSLocalizedFailureReasonErrorKey:@"Invalid OAuth response received from server."}];

        failure(error);

        return;
    }

    AFHTTPResponseSerializer *defaultSerializer = self.responseSerializer;
    self.responseSerializer = [AFHTTPResponseSerializer serializer];

    NSMutableDictionary *parameters = [[self.requestSerializer OAuthParameters] mutableCopy];
    parameters[BDBOAuth1OAuthTokenParameter]    = requestToken.token;
    parameters[BDBOAuth1OAuthVerifierParameter] = requestToken.verifier;

    NSString *URLString = [[NSURL URLWithString:accessPath relativeToURL:self.baseURL] absoluteString];
    NSError *error;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:URLString parameters:parameters error:&error];

    if (error) {
        failure(error);

        return;
    }

    void (^completionBlock)(NSURLResponse * __unused, id, NSError *) = ^(NSURLResponse * __unused response, id responseObject, NSError *completionError) {
        self.responseSerializer = defaultSerializer;
        self.requestSerializer.requestToken = nil;

        if (completionError) {
            failure(completionError);

            return;
        }

        BDBOAuth1Credential *accessToken = [BDBOAuth1Credential credentialWithQueryString:[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]];
        [self.requestSerializer saveAccessToken:accessToken];

        success(accessToken);
    };

    NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:completionBlock];
    [task resume];
}

@end

#endif
