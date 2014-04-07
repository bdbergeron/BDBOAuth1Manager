//
//  BDBOAuth1RequestSerializer.m
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

#import <CommonCrypto/CommonHMAC.h>

#import "BDBOAuth1RequestSerializer.h"

#import "NSDictionary+BDBOAuth1Manager.h"
#import "NSString+BDBOAuth1Manager.h"


NSString * const BDBOAuth1ErrorDomain = @"BDBOAuth1ErrorDomain";


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
    return [[[self class] alloc] initWithToken:token secret:secret expiration:expiration];
}

+ (instancetype)tokenWithQueryString:(NSString *)queryString
{
    return [[[self class] alloc] initWithQueryString:queryString];
}

- (id)initWithToken:(NSString *)token secret:(NSString *)secret expiration:(NSDate *)expiration
{
    self = [super init];
    if (self)
    {
        _token = token;
        _secret = secret;
        _expiration = expiration;
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
        _verifier = verifier;

        NSMutableDictionary *mutableUserInfo = [attributes mutableCopy];
        [mutableUserInfo removeObjectsForKeys:@[@"oauth_token", @"oauth_token_secret", @"oauth_verifier", @"oauth_token_duration"]];
        if (mutableUserInfo.count > 0)
            _userInfo = [NSDictionary dictionaryWithDictionary:mutableUserInfo];
    }
    return self;
}

#pragma mark Properties
- (BOOL)isExpired
{
    if (!self.expiration)
        return NO;
    else
        return [self.expiration compare:[NSDate date]] == NSOrderedAscending;
}

#pragma mark NSCoding
- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self)
    {
        _token      = [decoder decodeObjectForKey:NSStringFromSelector(@selector(token))];
        _secret     = [decoder decodeObjectForKey:NSStringFromSelector(@selector(secret))];
        _verifier   = [decoder decodeObjectForKey:NSStringFromSelector(@selector(verifier))];
        _expiration = [decoder decodeObjectForKey:NSStringFromSelector(@selector(expiration))];
        _userInfo   = [decoder decodeObjectForKey:NSStringFromSelector(@selector(userInfo))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.token forKey:NSStringFromSelector(@selector(token))];
    [coder encodeObject:self.secret forKey:NSStringFromSelector(@selector(secret))];
    [coder encodeObject:self.verifier forKey:NSStringFromSelector(@selector(verifier))];
    [coder encodeObject:self.expiration forKey:NSStringFromSelector(@selector(expiration))];
    [coder encodeObject:self.userInfo forKey:NSStringFromSelector(@selector(userInfo))];
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone
{
    BDBOAuthToken *copy = [[[self class] allocWithZone:zone] initWithToken:self.token secret:self.secret expiration:self.expiration];
    copy.verifier = self.verifier;
    copy.userInfo = self.userInfo;
    return copy;
}

@end


#pragma mark -
@interface BDBOAuth1RequestSerializer ()

@property (nonatomic, copy) NSString *service;
@property (nonatomic, copy) NSString *consumerKey;
@property (nonatomic, copy) NSString *consumerSecret;

- (NSString *)OAuthSignatureForMethod:(NSString *)method
                            URLString:(NSString *)URLString
                           parameters:(NSDictionary *)parameters
                                error:(NSError *__autoreleasing *)error;
- (NSString *)OAuthAuthorizationHeaderForMethod:(NSString *)method
                                      URLString:(NSString *)URLString
                                     parameters:(NSDictionary *)parameters
                                          error:(NSError *__autoreleasing *)error;

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
        _service = service;
        _consumerKey = key;
        _consumerSecret = secret;
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
    CFUUIDBytes uuidBytes = CFUUIDGetUUIDBytes(uuid);
    CFRelease(uuid);
    
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000) || (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= 1090)
    parameters[@"oauth_nonce"] = [[NSData dataWithBytes:&uuidBytes length:sizeof(uuidBytes)] base64EncodedStringWithOptions:0];
#else
    parameters[@"oauth_nonce"] = [[NSData dataWithBytes:&uuidBytes length:sizeof(uuidBytes)] base64Encoding];
#endif
                                  
    return parameters;
}

- (NSString *)OAuthSignatureForMethod:(NSString *)method
                            URLString:(NSString *)URLString
                           parameters:(NSDictionary *)parameters
                                error:(NSError *__autoreleasing *)error
{
    NSMutableURLRequest *request = [super requestWithMethod:@"GET" URLString:URLString parameters:parameters error:error];

    [request setHTTPMethod:method];

    NSString *secret = @"";
    if (self.accessToken)
        secret = self.accessToken.secret;
    else if (self.requestToken)
        secret = self.requestToken.secret;

    NSString *secretString = [[self.consumerSecret URLEncode] stringByAppendingFormat:@"&%@", [secret URLEncode]];
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
    NSString *requestURL    = [[[[request URL] absoluteString] componentsSeparatedByString:@"?"][0] URLEncode];

    NSArray *sortedQueryString = [[[[request URL] query] componentsSeparatedByString:@"&"] sortedArrayUsingSelector:@selector(compare:)];
    NSString *queryString   = [[sortedQueryString componentsJoinedByString:@"&"] URLEncode];

    NSString *requestString = [NSString stringWithFormat:@"%@&%@&%@", requestMethod, requestURL, queryString];
    NSData *requestData = [requestString dataUsingEncoding:NSUTF8StringEncoding];

    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CCHmacContext context;
    CCHmacInit(&context, kCCHmacAlgSHA1, [secretData bytes], [secretData length]);
    CCHmacUpdate(&context, [requestData bytes], [requestData length]);
    CCHmacFinal(&context, digest);

#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000) || (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= 1090)
    return [[NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH] base64EncodedStringWithOptions:0];
#else
    return [[NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH] base64Encoding];
#endif
}

- (NSString *)OAuthAuthorizationHeaderForMethod:(NSString *)method
                                      URLString:(NSString *)URLString
                                     parameters:(NSDictionary *)parameters
                                          error:(NSError *__autoreleasing *)error
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
    mutableAuthorizationParameters[@"oauth_signature"] = [self OAuthSignatureForMethod:method URLString:URLString parameters:mutableParameters error:error];

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
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(NSDictionary *)parameters
                                     error:(NSError *__autoreleasing *)error
{
    NSMutableDictionary *mutableParameters = [parameters mutableCopy];
    for (NSString *key in parameters)
        if ([key hasPrefix:@"oauth_"])
            [mutableParameters removeObjectForKey:key];

    NSMutableURLRequest *request = [super requestWithMethod:method
                                                  URLString:URLString
                                                 parameters:mutableParameters
                                                      error:error];

    // Only use parameters in the request entity body (with a content-type of `application/x-www-form-urlencoded`).
    // See RFC 5849, Section 3.4.1.3.1 http://tools.ietf.org/html/rfc5849#section-3.4
    NSDictionary *authorizationParameters = parameters;
    if (![self.HTTPMethodsEncodingParametersInURI containsObject:method.uppercaseString])
        if (![[request valueForHTTPHeaderField:@"Content-Type"] hasPrefix:@"application/x-www-form-urlencoded"])
            authorizationParameters = nil;

    [request setValue:[self OAuthAuthorizationHeaderForMethod:method URLString:URLString parameters:authorizationParameters error:error] forHTTPHeaderField:@"Authorization"];
    [request setHTTPShouldHandleCookies:NO];

    return request;
}

- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                              URLString:(NSString *)URLString
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))block
                                                  error:(NSError *__autoreleasing *)error
{
    NSMutableDictionary *mutableParameters = [parameters mutableCopy];
    for (NSString *key in parameters)
        if ([key hasPrefix:@"oauth_"])
            [mutableParameters removeObjectForKey:key];

    NSMutableURLRequest *request = [super multipartFormRequestWithMethod:method
                                                               URLString:URLString
                                                              parameters:mutableParameters
                                               constructingBodyWithBlock:block
                                                                   error:error];

    // Only use parameters in the request entity body (with a content-type of `application/x-www-form-urlencoded`).
    // See RFC 5849, Section 3.4.1.3.1 http://tools.ietf.org/html/rfc5849#section-3.4
    NSDictionary *authorizationParameters = parameters;
    if (!([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"] || [method isEqualToString:@"DELETE"]))
        if (![[request valueForHTTPHeaderField:@"Content-Type"] hasPrefix:@"application/x-www-form-urlencoded"])
            authorizationParameters = nil;

    [request setValue:[self OAuthAuthorizationHeaderForMethod:method URLString:URLString parameters:authorizationParameters error:error] forHTTPHeaderField:@"Authorization"];
    [request setHTTPShouldHandleCookies:NO];

    return request;
}

@end
