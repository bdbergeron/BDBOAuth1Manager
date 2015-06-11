//
//  BDBOAuth1RequestSerializer.h
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

#import <AFNetworking/AFURLRequestSerialization.h>


FOUNDATION_EXPORT NSString * const BDBOAuth1ErrorDomain;

FOUNDATION_EXPORT NSString * const BDBOAuth1OAuthTokenParameter;
FOUNDATION_EXPORT NSString * const BDBOAuth1OAuthTokenSecretParameter;
FOUNDATION_EXPORT NSString * const BDBOAuth1OAuthVerifierParameter;
FOUNDATION_EXPORT NSString * const BDBOAuth1OAuthTokenDurationParameter;
FOUNDATION_EXPORT NSString * const BDBOAuth1OAuthSignatureParameter;
FOUNDATION_EXPORT NSString * const BDBOAuth1OAuthCallbackParameter;


#pragma mark -
@interface BDBOAuth1Credential : NSObject
<NSCoding, NSCopying>

/**
 *  Token ('oauth_token')
 */
@property (nonatomic, copy, readonly) NSString *token;

/**
 *  Token secret ('oauth_token_secret')
 */
@property (nonatomic, copy, readonly) NSString *secret;

/**
 *  Verifier ('oauth_verifier')
 */
@property (nonatomic, copy) NSString *verifier;

/**
 *  Check whether or not this token is expired.
 */
@property (nonatomic, assign, readonly, getter = isExpired) BOOL expired;

/**
 *  Additional custom (non-OAuth) parameters included with this credential.
 */
@property (nonatomic) NSDictionary *userInfo;


/**
 *  ---------------------------------------------------------------------------------------
 * @name Initialization
 *  ---------------------------------------------------------------------------------------
 */
#pragma mark Initialization

/**
 *  Create a new BDBOAuth1Credential instance with the given token, token secret, and verifier.
 *
 *  @param token      OAuth token ('oauth_token').
 *  @param secret     OAuth token secret ('oauth_token_secret').
 *  @param expiration Expiration date or nil if the credential does not expire.
 *
 *  @return New BDBOAuth1Credential.
 */
+ (instancetype)credentialWithToken:(NSString *)token
                             secret:(NSString *)secret
                         expiration:(NSDate *)expiration;

/**
 *  Instantiate a new BDBOAuth1Credential instance with the given token, token secret, and verifier.
 *
 *  @param token      OAuth token ('oauth_token').
 *  @param secret     OAuth token secret ('oauth_token_secret').
 *  @param expiration Expiration date or nil if the credential does not expire.
 *
 *  @return New BDBOAuth1Credential.
 */
- (instancetype)initWithToken:(NSString *)token
                       secret:(NSString *)secret
                   expiration:(NSDate *)expiration;

/**
 *  Create a new BDBOAuth1Credential instance using parameters in the given URL query string.
 *
 *  @param queryString URL query string containing OAuth token parameters.
 *
 *  @return New BDBOAuth1Credential.
 */
+ (instancetype)credentialWithQueryString:(NSString *)queryString;

/**
 *  Instantiate a new BDBOAuth1Credential instance using parameters in the given URL query string.
 *
 *  @param queryString URL query string containing OAuth token parameters.
 *
 *  @return New BDBOAuth1Credential.
 */
- (instancetype)initWithQueryString:(NSString *)queryString;

@end


#pragma mark -
@interface BDBOAuth1RequestSerializer : AFHTTPRequestSerializer

/**
 *  OAuth request token.
 */
@property (nonatomic, copy) BDBOAuth1Credential *requestToken;

/**
 *  OAuth access token.
 */
@property (nonatomic, copy, readonly) BDBOAuth1Credential *accessToken;


/**
 *  ---------------------------------------------------------------------------------------
 * @name Initialization
 *  ---------------------------------------------------------------------------------------
 */
#pragma mark Initialization

/**
 *  Create a new BDBOAuth1RequestSerializer instance for the given service with its consumerKey and consumerSecret.
 *
 *  @param service        Service (base URL) this request serializer is used for.
 *  @param consumerKey    OAuth consumer key.
 *  @param consumerSecret OAuth consumer secret.
 *
 *  @return New BDBOAuth1RequestSerializer for the specified service.
 */
+ (instancetype)serializerForService:(NSString *)service
                     withConsumerKey:(NSString *)consumerKey
                      consumerSecret:(NSString *)consumerSecret;

/**
 *  Instantiate a new BDBOAuth1RequestSerializer instance for the given service with its consumerKey and consumerSecret.
 *
 *  @param service        Service (base URL) this request serializer is used for.
 *  @param consumerKey    OAuth consumer key.
 *  @param consumerSecret OAuth consumer secret.
 *
 *  @return New BDBOAuth1RequestSerializer for the specified service.
 */
- (instancetype)initWithService:(NSString *)service
                    consumerKey:(NSString *)consumerKey
                 consumerSecret:(NSString *)consumerSecret;


/**
 *  ---------------------------------------------------------------------------------------
 * @name Storing the Access Token
 *  ---------------------------------------------------------------------------------------
 */
#pragma mark Storing the Access Token

/**
 *  Save the given OAuth access token in the user's keychain for future use with this serializer's service.
 *
 *  @param accessToken OAuth access token.
 *
 *  @return Success of keychain item add/update operation.
 */
- (BOOL)saveAccessToken:(BDBOAuth1Credential *)accessToken;

/**
 *  Remove the access token currently stored in the keychain for this serializer's service.
 *
 *  @return Success of keychain item removal operation.
 */
- (BOOL)removeAccessToken;


/**
 *  ---------------------------------------------------------------------------------------
 * @name OAuth Parameters
 *  ---------------------------------------------------------------------------------------
 */
#pragma mark OAuth Parameters

/**
 *  Retrieve the set of OAuth parameters to be included in authorized HTTP requests.
 *
 *  @return Dictionary of OAuth parameters.
 */
- (NSDictionary *)OAuthParameters;

@end

