//
//  BDBOAuth1RequestSerializer.h
//
//  Created by Bradley Bergeron on 11/10/2013.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import "AFURLRequestSerialization.h"


#pragma mark -
@interface BDBOAuthToken : NSObject

@property (nonatomic, copy, readonly) NSString *token;
@property (nonatomic, copy, readonly) NSString *secret;
@property (nonatomic, copy)           NSString *verifier;

@property (nonatomic, assign, readonly, getter = isExpired) BOOL expired;

+ (instancetype)tokenWithToken:(NSString *)token secret:(NSString *)secret expiration:(NSDate *)expiration;
+ (instancetype)tokenWithQueryString:(NSString *)queryString;

@end


#pragma mark -
@interface BDBOAuth1RequestSerializer : AFHTTPRequestSerializer

@property (nonatomic, copy) BDBOAuthToken *accessToken;

+ (instancetype)serializerWithConsumerKey:(NSString *)consumerKey
                           consumerSecret:(NSString *)consumerSecret;

- (NSDictionary *)OAuthParameters;

@end

