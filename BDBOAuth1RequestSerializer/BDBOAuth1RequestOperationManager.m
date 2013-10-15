//
//  BDBOAuth1RequestOperationManager.m
//  BDBOAuth1RequestSerializerDemo
//
//  Created by Bradley Bergeron on 10/14/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import "BDBOAuth1RequestOperationManager.h"


#pragma mark -
@implementation BDBOAuth1RequestOperationManager

- (void)fetchRequestTokenWithPath:(NSString *)requestPath
                           method:(NSString *)method
                      callbackURL:(NSURL *)callbackURL
                            scope:(NSString *)scope
                          success:(void (^)(BDBOAuthToken *, id))success
                          failure:(void (^)(NSError *))failure
{
    NSMutableDictionary *parameters = [[self.requestSerializer OAuthParameters] mutableCopy];
    parameters[@"oauth_callback"] = [callbackURL absoluteString];
    if (scope && !self.accessToken)
        parameters[@"scope"] = scope;

    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:requestPath parameters:parameters];
    [request setHTTPBody:nil];

    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success)
            success([BDBOAuthToken tokenWithQueryString:operation.responseString], responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure)
            failure(error);
    }];

    [self.operationQueue addOperation:operation];
}

- (void)fetchAccessTokenWithPath:(NSString *)accessPath
                          method:(NSString *)method
                    requestToken:(BDBOAuthToken *)requestToken
                         success:(void (^)(BDBOAuthToken *, id))success
                         failure:(void (^)(NSError *))failure
{
    NSMutableDictionary *parameters = [[self.requestSerializer OAuthParameters] mutableCopy];
    parameters[@"oauth_token"]    = requestToken.token;
    parameters[@"oauth_verifier"] = requestToken.verifier;

    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:accessPath parameters:parameters];

    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success)
            success([BDBOAuthToken tokenWithQueryString:operation.responseString], responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure)
            failure(error);
    }];

    [self.operationQueue addOperation:operation];
}

@end
