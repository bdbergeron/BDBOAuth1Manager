//
//  BDBOAuth1RequestOperationManager.h
//  BDBOAuth1RequestSerializerDemo
//
//  Created by Bradley Bergeron on 10/14/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"
#import "BDBOAuth1RequestSerializer.h"


#pragma mark -
@interface BDBOAuth1RequestOperationManager : AFHTTPRequestOperationManager

@property (nonatomic, strong) BDBOAuth1RequestSerializer *requestSerializer;
@property (nonatomic, strong) BDBOAuthToken *accessToken;

//- (void)authorizeUsingOAuthWithRequestPath:(NSString *)requestPath
//                         authorizationPath:(NSString *)authorizationPath
//                               callbackURL:(NSURL *)callbackURL
//                                accessPath:(NSString *)accessPath
//                                    method:(NSString *)method
//                                     scope:(NSString *)scope
//                                   success:(void (^)(BDBOAuthToken *accessToken, id rsponseObject))success
//                                   failure:(void (^)(NSError *error))failure;

- (void)fetchRequestTokenWithPath:(NSString *)requestPath
                           method:(NSString *)method
                      callbackURL:(NSURL *)callbackURL
                            scope:(NSString *)scope
                          success:(void (^)(BDBOAuthToken *, id))success
                          failure:(void (^)(NSError *))failure;

- (void)fetchAccessTokenWithPath:(NSString *)accessPath
                          method:(NSString *)method
                    requestToken:(BDBOAuthToken *)requestToken
                         success:(void (^)(BDBOAuthToken *, id))success
                         failure:(void (^)(NSError *))failure;

@end
