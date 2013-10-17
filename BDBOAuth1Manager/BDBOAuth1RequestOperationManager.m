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
        self.requestSerializer  = [BDBOAuth1RequestSerializer serializerForService:url.host withConsumerKey:key consumerSecret:secret];
    }
    return self;
}

#pragma mark Access Token
- (BOOL)isAuthorized
{
    return self.requestSerializer.accessToken != nil;
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

    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:[[NSURL URLWithString:requestPath relativeToURL:self.baseURL] absoluteString] parameters:parameters];
    [request setHTTPBody:nil];

    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.responseSerializer = defaultSerializer;
        if (success)
            success([BDBOAuthToken tokenWithQueryString:operation.responseString]);
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
    AFHTTPResponseSerializer *defaultSerializer = self.responseSerializer;
    self.responseSerializer = [AFHTTPResponseSerializer serializer];

    NSMutableDictionary *parameters = [[self.requestSerializer OAuthParameters] mutableCopy];
    parameters[@"oauth_token"]    = requestToken.token;
    parameters[@"oauth_verifier"] = requestToken.verifier;

    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:[[NSURL URLWithString:accessPath relativeToURL:self.baseURL] absoluteString] parameters:parameters];

    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.responseSerializer = defaultSerializer;
        if (success)
            success([BDBOAuthToken tokenWithQueryString:operation.responseString]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.responseSerializer = defaultSerializer;
        if (failure)
            failure(error);
    }];

    [self.operationQueue addOperation:operation];
}

@end
