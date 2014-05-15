//
//  BDBOAuth1RequestSerializer.h
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

#import "AFURLRequestSerialization.h"


FOUNDATION_EXPORT NSString * const BDBOAuth1ErrorDomain;

FOUNDATION_EXPORT NSString * const BDBOAuth1OAuthTokenParameter;
FOUNDATION_EXPORT NSString * const BDBOAuth1OAuthTokenSecretParameter;
FOUNDATION_EXPORT NSString * const BDBOAuth1OAuthVerifierParameter;
FOUNDATION_EXPORT NSString * const BDBOAuth1OAuthTokenDurationParameter;
FOUNDATION_EXPORT NSString * const BDBOAuth1OAuthSignatureParameter;
FOUNDATION_EXPORT NSString * const BDBOAuth1OAuthCallbackParameter;


#pragma mark -
@interface BDBOAuthToken : NSObject
<NSCoding, NSCopying>

@property (nonatomic, copy, readonly) NSString *token;
@property (nonatomic, copy, readonly) NSString *secret;
@property (nonatomic, copy)           NSString *verifier;

@property (nonatomic, assign, readonly, getter = isExpired) BOOL expired;

@property (nonatomic) NSDictionary *userInfo;

#pragma mark Initialization
+ (instancetype)tokenWithToken:(NSString *)token secret:(NSString *)secret expiration:(NSDate *)expiration;
+ (instancetype)tokenWithQueryString:(NSString *)queryString;

@end


#pragma mark -
@interface BDBOAuth1RequestSerializer : AFHTTPRequestSerializer

@property (nonatomic, copy) BDBOAuthToken *requestToken;
@property (nonatomic, copy, readonly) BDBOAuthToken *accessToken;

#pragma mark Initialization
+ (instancetype)serializerForService:(NSString *)service withConsumerKey:(NSString *)key consumerSecret:(NSString *)secret;
- (id)initWithService:(NSString *)service consumerKey:(NSString *)key consumerSecret:(NSString *)secret;

#pragma mark OAuth
- (NSDictionary *)OAuthParameters;

#pragma mark AccessToken
- (BOOL)saveAccessToken:(BDBOAuthToken *)accessToken;
- (BOOL)removeAccessToken;

@end

