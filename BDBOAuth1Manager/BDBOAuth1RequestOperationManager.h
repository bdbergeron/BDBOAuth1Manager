//
//  BDBOAuth1RequestOperationManager.h
//
//  Created by Bradley Bergeron on 10/14/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import <AFNetworking/AFHTTPRequestOperationManager.h>

#import "BDBOAuth1RequestSerializer.h"


#pragma mark -
@interface BDBOAuth1RequestOperationManager : AFHTTPRequestOperationManager

@property (nonatomic, strong) BDBOAuth1RequestSerializer *requestSerializer;
@property (nonatomic, assign, readonly, getter = isAuthorized) BOOL authorized;

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

@end
