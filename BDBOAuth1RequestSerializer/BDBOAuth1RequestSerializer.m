//
//  BDBOAuth1RequestSerializer.m
//
//  Created by Bradley Bergeron on 11/10/2013.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import <CommonCrypto/CommonHMAC.h>

#import "BDBOAuth1RequestSerializer.h"

#import "NSDictionary+BDBOAuth.h"
#import "NSString+BDBOAuth.h"
#import "NSURL+BDBOAuth.h"


#pragma mark -
@interface BDBOAuthToken ()

@property (nonatomic, copy, readwrite) NSString *token;
@property (nonatomic, copy, readwrite) NSString *secret;

@property (nonatomic, strong) NSDate *expiration;

- (id)initWithToken:(NSString *)token secret:(NSString *)secret expiration:(NSDate *)expiration;
- (id)initWithQueryString:(NSString *)queryString;

@end


#pragma mark -
@implementation BDBOAuthToken

+ (instancetype)tokenWithToken:(NSString *)token secret:(NSString *)secret expiration:(NSDate *)expiration
{
    return [[BDBOAuthToken alloc] initWithToken:token secret:secret expiration:expiration];
}

+ (instancetype)tokenWithQueryString:(NSString *)queryString
{
    return [[BDBOAuthToken alloc] initWithQueryString:queryString];
}

- (id)initWithToken:(NSString *)token secret:(NSString *)secret expiration:(NSDate *)expiration
{
    self = [super init];
    if (self)
    {
        self.token = token;
        self.secret = secret;
        self.expiration = expiration;
    }
    return self;
}

- (id)initWithQueryString:(NSString *)queryString
{
    if (!queryString || queryString.length == 0)
        return nil;

    NSDictionary *attributes = [NSDictionary dictionaryFromQueryString:queryString];

    if (attributes.count == 0)
        return nil;

    NSString *token  = attributes[@"oauth_token"];
    NSString *secret = attributes[@"oauth_token_secret"];

    NSDate *expiration = nil;
    if (attributes[@"oauth_token_duration"])
        expiration = [NSDate dateWithTimeIntervalSinceNow:[attributes[@"oauth_token_duration"] doubleValue]];

    self = [self initWithToken:token secret:secret expiration:expiration];
    if (self)
    {

    }
    return self;
}

- (BOOL)isExpired
{
    return [self.expiration compare:[NSDate date]] == NSOrderedDescending;
}

@end


#pragma mark -
@interface BDBOAuth1RequestSerializer ()

@property (nonatomic, copy) NSString *consumerKey;
@property (nonatomic, copy) NSString *consumerSecret;

- (NSString *)OAuthSignatureForMethod:(NSString *)method URLString:(NSString *)URLString parameters:(NSDictionary *)parameters;
- (NSString *)authorizationHeaderForMethod:(NSString *)method URLString:(NSString *)URLString parameters:(NSDictionary *)parameters;

@end


#pragma mark -
@implementation BDBOAuth1RequestSerializer

+ (instancetype)serializerWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret
{
    BDBOAuth1RequestSerializer *serializer = [[super alloc] init];
    serializer.consumerKey = consumerKey;
    serializer.consumerSecret = consumerSecret;
    return serializer;
}

- (NSDictionary *)OAuthParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"oauth_version"] = @"1.0";
    parameters[@"oauth_consumer_key"] = self.consumerKey;
    parameters[@"oauth_timestamp"] = [@(floor([[NSDate date] timeIntervalSince1970])) stringValue];
    parameters[@"oauth_signature_method"] = @"HMAC-SHA1";

    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    parameters[@"oauth_nonce"] = (__bridge id)(uuidString);

    return parameters;
}

#pragma mark HMAC-SHA1 Signature
- (NSString *)OAuthSignatureForMethod:(NSString *)method URLString:(NSString *)URLString parameters:(NSDictionary *)parameters
{
    NSMutableURLRequest *request = [super requestWithMethod:@"GET" URLString:URLString parameters:parameters];
    [request setHTTPMethod:method];

    NSData *secretData = [[self.consumerSecret stringByAppendingFormat:@"&%@", self.accessToken.secret] dataUsingEncoding:NSUTF8StringEncoding];

    /**
     * Create signature from request data
     *
     * 1. Convert the HTTP Method to uppercase and set the output string equal to this value.
     * 2. Append the '&' character to the output string.
     * 3. Percent encode the URL and append it to the output string.
     * 4. Append the '&' character to the output string.
     * 5. Percent encode the query string and append it to the output string.
     */
    NSString *requestMethod = [[request HTTPMethod] uppercaseString];
    NSString *requestString = [[request.URL.absoluteString componentsSeparatedByString:@"?"][0] URLEncode];
    NSString *queryString   = [[[[[[request URL] query] componentsSeparatedByString:@"&"] sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@"&"] URLEncode];
    NSData *requestData = [[NSString stringWithFormat:@"%@&%@&%@", requestMethod, requestString, queryString] dataUsingEncoding:NSUTF8StringEncoding];

    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CCHmacContext context;
    CCHmacInit(&context, kCCHmacAlgSHA1, [secretData bytes], [secretData length]);
    CCHmacUpdate(&context, [requestData bytes], [requestData length]);
    CCHmacFinal(&context, digest);

    return [[NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH] base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
}

#pragma mark Authorization Headers
- (NSString *)authorizationHeaderForMethod:(NSString *)method URLString:(NSString *)URLString parameters:(NSDictionary *)parameters
{
    NSMutableDictionary *mutableParameters;
    if (parameters)
        mutableParameters = [parameters mutableCopy];
    else
        mutableParameters = [NSMutableDictionary dictionary];

    NSMutableDictionary *mutableAuthorizationParameters = [NSMutableDictionary dictionary];

    if (self.consumerKey && self.consumerSecret)
    {
        [mutableAuthorizationParameters addEntriesFromDictionary:[self OAuthParameters]];
        if (self.accessToken)
            mutableAuthorizationParameters[@"oauth_token"] = self.accessToken.token;
    }

    [mutableParameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([key isKindOfClass:[NSString class]] && [key hasPrefix:@"oauth_"])
            mutableAuthorizationParameters[key] = obj;
    }];

    [mutableParameters addEntriesFromDictionary:mutableAuthorizationParameters];
    mutableAuthorizationParameters[@"oauth_signature"] = [self OAuthSignatureForMethod:method URLString:URLString parameters:mutableParameters];

    NSArray *sortedComponents = [[[mutableAuthorizationParameters queryStringFromDictionary] componentsSeparatedByString:@"&"] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableArray *mutableComponents = [NSMutableArray array];
    for (NSString *component in sortedComponents)
    {
        NSArray *subcomponents = [component componentsSeparatedByString:@"="];
        if ([subcomponents count] == 2)
            [mutableComponents addObject:[NSString stringWithFormat:@"%@=\"%@\"", subcomponents[0], subcomponents[1]]];
    }

    return [NSString stringWithFormat:@"OAuth %@", [mutableComponents componentsJoinedByString:@", "]];
}

- (void)setAuthorizationHeaderFieldWithOAuthToken:(NSString *)token
{
    [self setValue:[NSString stringWithFormat:@"Token token=\"%@\"", token] forHTTPHeaderField:@"Authorization"];
}


#pragma mark URL Requests
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method URLString:(NSString *)URLString parameters:(NSDictionary *)parameters
{
    NSMutableDictionary *mutableParameters = [parameters mutableCopy];
    for (NSString *key in parameters)
        if ([key hasPrefix:@"oauth_"])
            [mutableParameters removeObjectForKey:key];

    NSMutableURLRequest *request = [super requestWithMethod:method URLString:URLString parameters:mutableParameters];

    // Only use parameters in the HTTP POST request body (with a content-type of `application/x-www-form-urlencoded`).
    // See RFC 5849, Section 3.4.1.3.1 http://tools.ietf.org/html/rfc5849#section-3.4
    NSDictionary *authorizationParameters = parameters;
    if ([method isEqualToString:@"POST"])
        if (![[request valueForHTTPHeaderField:@"Content-Type"] hasPrefix:@"application/x-www-form-urlencoded"])
            authorizationParameters = nil;

    [request setValue:[self authorizationHeaderForMethod:method URLString:URLString parameters:authorizationParameters] forHTTPHeaderField:@"Authorization"];
    [request setHTTPShouldHandleCookies:NO];

    return request;
}

- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method URLString:(NSString *)URLString parameters:(NSDictionary *)parameters constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))block
{
    NSMutableDictionary *mutableParameters = [parameters mutableCopy];
    for (NSString *key in parameters)
        if ([key hasPrefix:@"oauth_"])
            [mutableParameters removeObjectForKey:key];

    NSMutableURLRequest *request = [super multipartFormRequestWithMethod:method URLString:URLString parameters:mutableParameters constructingBodyWithBlock:block];

    // Only use parameters in the HTTP POST request body (with a content-type of `application/x-www-form-urlencoded`).
    // See RFC 5849, Section 3.4.1.3.1 http://tools.ietf.org/html/rfc5849#section-3.4
    NSDictionary *authorizationParameters = parameters;
    if ([method isEqualToString:@"POST"])
        if (![[request valueForHTTPHeaderField:@"Content-Type"] hasPrefix:@"application/x-www-form-urlencoded"])
            authorizationParameters = nil;

    [request setValue:[self authorizationHeaderForMethod:method URLString:URLString parameters:authorizationParameters] forHTTPHeaderField:@"Authorization"];
    [request setHTTPShouldHandleCookies:NO];

    return request;
}

@end
