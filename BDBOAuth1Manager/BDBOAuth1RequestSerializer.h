//
//  BDBOAuth1RequestSerializer.h
//
//  Created by Bradley Bergeron on 11/10/2013.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import "AFURLRequestSerialization.h"


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

