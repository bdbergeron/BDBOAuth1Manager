//
//  BDBOAuth1SessionManager.h
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

#import <AFNetworking/AFHTTPSessionManager.h>

#import "BDBOAuth1RequestSerializer.h"

#pragma mark -
@interface BDBOAuth1SessionManager : AFHTTPSessionManager

/**
 *  BDBOAuth1RequestSerializer instance used to serialize HTTP requests.
 */
@property (nonatomic) BDBOAuth1RequestSerializer *requestSerializer;


/**
 *  ---------------------------------------------------------------------------------------
 * @name Initialization
 *  ---------------------------------------------------------------------------------------
 */
#pragma mark Initialization

/**
 *  Initialize a new BDBOAuth1SessionManager instance with the given baseURL, consumerKey, and consumerSecret.
 *
 *  @param baseURL        Base URL for HTTP requests.
 *  @param consumerKey    OAuth consumer key.
 *  @param consumerSecret OAuth consumer secret.
 *
 *  @return New BDBOAuth1SessionManager instance.
 */
- (instancetype)initWithBaseURL:(NSURL *)baseURL
                    consumerKey:(NSString *)consumerKey
                 consumerSecret:(NSString *)consumerSecret;


/**
 *  ---------------------------------------------------------------------------------------
 * @name Authorization Status
 *  ---------------------------------------------------------------------------------------
 */
#pragma mark Authorization Status

/**
 *  Check whehter or not this manager instance has a valid access token.
 */
@property (nonatomic, assign, readonly, getter = isAuthorized) BOOL authorized;

/**
 *  Deauthorize this manager instance and remove any associated access token from the keychain.
 *
 *  @return YES if an access token was found and removed from the keychain, NO otherwise.
 */
- (BOOL)deauthorize;


/**
 *  ---------------------------------------------------------------------------------------
 * @name OAuth Handshake
 *  ---------------------------------------------------------------------------------------
 */
#pragma mark OAuth Handshake

/**
 *  Fetch an OAuth request token.
 *
 *  @param requestPath OAuth request token endpoint.
 *  @param method      HTTP method for fetching OAuth request token.
 *  @param callbackURL The URL to be set for oauth_callback.
 *  @param scope       Authorization scope.
 *  @param success     Completion block performed upon successful acquisition of the OAuth request token.
 *  @param failure     Completion block performed if the OAuth request token could not be acquired.
 */
- (void)fetchRequestTokenWithPath:(NSString *)requestPath
                           method:(NSString *)method
                      callbackURL:(NSURL *)callbackURL
                            scope:(NSString *)scope
                          success:(void (^)(BDBOAuth1Credential *requestToken))success
                          failure:(void (^)(NSError *error))failure;


/**
 *  Fetch an OAuth access token using a previously-acquired request token.
 *
 *  @param accessPath   OAuth access token endpoint.
 *  @param method       HTTP method for fetching OAuth access token.
 *  @param requestToken OAuth request token.
 *  @param success      Completion block performed upon successful acquisition of the OAuth access token.
 *  @param failure      Completion block performed if the OAuth access token could not be acquired.
 */
- (void)fetchAccessTokenWithPath:(NSString *)accessPath
                          method:(NSString *)method
                    requestToken:(BDBOAuth1Credential *)requestToken
                         success:(void (^)(BDBOAuth1Credential *accessToken))success
                         failure:(void (^)(NSError *error))failure;

@end
