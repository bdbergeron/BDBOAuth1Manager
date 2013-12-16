//
//  BDBOAuth1RequestOperationManager.m
//
//  Created by Bradley Bergeron on 10/14/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import "BDBOAuth1RequestOperationManager.h"


#pragma mark -
@interface BDBOAuth1RequestOperationManager ()

@end


#pragma mark -
@implementation BDBOAuth1RequestOperationManager

#pragma mark Initialization
- (instancetype)initWithBaseURL:(NSURL *)url consumerKey:(NSString *)key consumerSecret:(NSString *)secret
{
    self = [super initWithBaseURL:url];
    if (self)
    {
        self.requestSerializer = [BDBOAuth1RequestSerializer serializerForService:url.host withConsumerKey:key consumerSecret:secret];
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

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (callbackURL)
        parameters[@"oauth_callback"] = [callbackURL absoluteString];
    if (scope && !self.requestSerializer.accessToken)
        parameters[@"scope"] = scope;

    NSString *URLString = [[NSURL URLWithString:requestPath relativeToURL:self.baseURL] absoluteString];
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:URLString parameters:parameters];

    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.responseSerializer = defaultSerializer;
        BDBOAuthToken *requestToken = [BDBOAuthToken tokenWithQueryString:operation.responseString];
        self.requestSerializer.requestToken = requestToken;
        if (success)
            success(requestToken);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.responseSerializer = defaultSerializer;
        if (failure)
            failure(error);
    }];

    [self.operationQueue addOperation:operation];
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

        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"oauth_token"]    = requestToken.token;
        parameters[@"oauth_verifier"] = requestToken.verifier;

        NSString *URLString = [[NSURL URLWithString:accessPath relativeToURL:self.baseURL] absoluteString];
        NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:URLString parameters:parameters];

        AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            self.responseSerializer = defaultSerializer;
            self.requestSerializer.requestToken = nil;
            BDBOAuthToken *accessToken = [BDBOAuthToken tokenWithQueryString:operation.responseString];
            [self.requestSerializer saveAccessToken:accessToken];
            if (success)
                success(accessToken);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            self.responseSerializer = defaultSerializer;
            self.requestSerializer.requestToken = nil;
            if (failure)
                failure(error);
        }];

        [self.operationQueue addOperation:operation];
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
