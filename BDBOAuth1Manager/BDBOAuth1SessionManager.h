//
//  BDBOAuth1SessionManager.h
//
//  Created by Bradley Bergeron on 10/17/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import <AFNetworking/AFHTTPSessionManager.h>

#import "BDBOAuth1RequestSerializer.h"

#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000) || (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= 1090)

#pragma mark -
@interface BDBOAuth1SessionManager : AFHTTPSessionManager

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

#endif
