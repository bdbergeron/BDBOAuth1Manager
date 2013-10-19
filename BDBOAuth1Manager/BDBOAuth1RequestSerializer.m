//
//  BDBOAuth1RequestSerializer.m
//
//  Created by Bradley Bergeron on 11/10/2013.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import <CommonCrypto/CommonHMAC.h>

#import "BDBOAuth1RequestSerializer.h"

#import "NSData+Base64.h"
#import "NSDictionary+BDBOAuth1Manager.h"
#import "NSString+BDBOAuth1Manager.h"


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

#pragma mark Initialization
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

    NSString *token    = attributes[@"oauth_token"];
    NSString *secret   = attributes[@"oauth_token_secret"];
    NSString *verifier = attributes[@"oauth_verifier"];

    NSDate *expiration = nil;
    if (attributes[@"oauth_token_duration"])
        expiration = [NSDate dateWithTimeIntervalSinceNow:[attributes[@"oauth_token_duration"] doubleValue]];

    self = [self initWithToken:token secret:secret expiration:expiration];
    if (self)
    {
        self.verifier = verifier;

        NSMutableDictionary *mutableUserInfo = [attributes mutableCopy];
        [mutableUserInfo removeObjectsForKeys:@[@"oauth_token", @"oauth_token_secret", @"oauth_verifier", @"oauth_token_duration"]];
        if (mutableUserInfo.count > 0)
            self.userInfo = [NSDictionary dictionaryWithDictionary:mutableUserInfo];
    }
    return self;
}

#pragma mark Properties
- (BOOL)isExpired
{
    return [self.expiration compare:[NSDate date]] == NSOrderedDescending;
}

#pragma mark NSCoding
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.token      = [aDecoder decodeObjectForKey:@"token"];
        self.secret     = [aDecoder decodeObjectForKey:@"secret"];
        self.verifier   = [aDecoder decodeObjectForKey:@"verifier"];
        self.expiration = [aDecoder decodeObjectForKey:@"expiration"];
        self.userInfo   = [aDecoder decodeObjectForKey:@"userInfo"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.token forKey:@"token"];
    [aCoder encodeObject:self.secret forKey:@"secret"];
    [aCoder encodeObject:self.verifier forKey:@"verifier"];
    [aCoder encodeObject:self.expiration forKey:@"expiration"];
    [aCoder encodeObject:self.userInfo forKey:@"userInfo"];
}

@end


#pragma mark -
@interface BDBOAuth1RequestSerializer ()

@property (nonatomic, copy) NSString *service;
@property (nonatomic, copy) NSString *consumerKey;
@property (nonatomic, copy) NSString *consumerSecret;

- (NSString *)OAuthSignatureForMethod:(NSString *)method URLString:(NSString *)URLString parameters:(NSDictionary *)parameters;
- (NSString *)OAuthAuthorizationHeaderForMethod:(NSString *)method URLString:(NSString *)URLString parameters:(NSDictionary *)parameters;

@end


#pragma mark -
@implementation BDBOAuth1RequestSerializer

#pragma mark Initialization
+ (instancetype)serializerForService:(NSString *)service withConsumerKey:(NSString *)key consumerSecret:(NSString *)secret
{
    return [[BDBOAuth1RequestSerializer alloc] initWithService:service consumerKey:key consumerSecret:secret];
}

- (id)initWithService:(NSString *)service consumerKey:(NSString *)key consumerSecret:(NSString *)secret
{
    self = [super init];
    if (self)
    {
        self.service = service;
        self.consumerKey = key;
        self.consumerSecret = secret;
    }
    return self;
}

#pragma mark Access Token
static NSDictionary *OAuthKeychainDictionaryForService(NSString *service)
{
    return @{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
             (__bridge id)kSecAttrService:service};
}

- (BDBOAuthToken *)accessToken
{
    NSMutableDictionary *dictionary = [OAuthKeychainDictionaryForService(self.service) mutableCopy];
    dictionary[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
    dictionary[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

    CFDataRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)dictionary, (CFTypeRef *)&result);
    NSData *data = (__bridge_transfer NSData *)result;

    if (status == noErr && data)
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    else
        return nil;
}

- (BOOL)saveAccessToken:(BDBOAuthToken *)accessToken
{
    NSMutableDictionary *dictionary = [OAuthKeychainDictionaryForService(self.service) mutableCopy];

    NSMutableDictionary *updateDictionary = [NSMutableDictionary dictionary];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:accessToken];
    updateDictionary[(__bridge id)kSecValueData] = data;

    OSStatus status;
    if ([self accessToken])
        status = SecItemUpdate((__bridge CFDictionaryRef)dictionary, (__bridge CFDictionaryRef)updateDictionary);
    else
    {
        [dictionary addEntriesFromDictionary:updateDictionary];
        status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);
    }

    if (status == noErr)
        return YES;
    else
        return NO;
}

- (BOOL)removeAccessToken
{
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)OAuthKeychainDictionaryForService(self.service));
    if (status == noErr)
        return YES;
    else
        return NO;
}

#pragma mark OAuth Parameters
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

- (NSString *)OAuthSignatureForMethod:(NSString *)method URLString:(NSString *)URLString parameters:(NSDictionary *)parameters
{
    NSMutableURLRequest *request = [super requestWithMethod:@"GET" URLString:URLString parameters:parameters];
    [request setHTTPMethod:method];

    NSString *secret = @"";
    if (self.accessToken)
        secret = self.accessToken.secret;

    NSString *secretString = [self.consumerSecret stringByAppendingFormat:@"&%@", secret];
    NSData *secretData = [secretString dataUsingEncoding:NSUTF8StringEncoding];

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
    NSString *requestURL    = [[request.URL.absoluteString componentsSeparatedByString:@"?"][0] URLEncode];
    NSString *queryString   = [[[[request.URL.query componentsSeparatedByString:@"&"] sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@"&"] URLEncode];

    NSString *requestString = [NSString stringWithFormat:@"%@&%@&%@", requestMethod, requestURL, queryString];
    NSData *requestData = [requestString dataUsingEncoding:NSUTF8StringEncoding];

    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CCHmacContext context;
    CCHmacInit(&context, kCCHmacAlgSHA1, [secretData bytes], [secretData length]);
    CCHmacUpdate(&context, [requestData bytes], [requestData length]);
    CCHmacFinal(&context, digest);

    return [[NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH] base64EncodedString];
}

#pragma mark Authorization Headers
- (NSString *)OAuthAuthorizationHeaderForMethod:(NSString *)method URLString:(NSString *)URLString parameters:(NSDictionary *)parameters
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

    NSArray *sortedComponents = [[[mutableAuthorizationParameters queryStringRepresentation] componentsSeparatedByString:@"&"] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableArray *mutableComponents = [NSMutableArray array];
    for (NSString *component in sortedComponents)
    {
        NSArray *subcomponents = [component componentsSeparatedByString:@"="];
        if ([subcomponents count] == 2)
            [mutableComponents addObject:[NSString stringWithFormat:@"%@=\"%@\"", subcomponents[0], subcomponents[1]]];
    }

    return [NSString stringWithFormat:@"OAuth %@", [mutableComponents componentsJoinedByString:@", "]];
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

    [request setValue:[self OAuthAuthorizationHeaderForMethod:method URLString:URLString parameters:authorizationParameters] forHTTPHeaderField:@"Authorization"];
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

    [request setValue:[self OAuthAuthorizationHeaderForMethod:method URLString:URLString parameters:authorizationParameters] forHTTPHeaderField:@"Authorization"];
    [request setHTTPShouldHandleCookies:NO];

    return request;
}

@end
