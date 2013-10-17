//
//  NSString+BDBOAuth1Manager.m
//
//  Created by Bradley David Bergeron on 9/14/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>

#import "NSString+BDBOAuth1Manager.h"


#pragma mark -
@implementation NSString (BDBOAuth1Manager)

#pragma mark Hashing
+ (instancetype)MD5HashForString:(NSString *)string
{
    return [string MD5Hash];
}

- (NSString *)MD5Hash
{
    const char *cStr = self.UTF8String;
    unsigned char digest[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];

    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];

    return output;
}

+ (instancetype)SHA1HashForString:(NSString *)string
{
    return [string SHA1Hash];
}

- (NSString*)SHA1Hash
{
    const char *cstr = [self cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:self.length];

    uint8_t digest[CC_SHA1_DIGEST_LENGTH];

    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);

    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];

    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}

#pragma mark Proper URL Encoding/Decoding
- (NSString *)URLEncode
{
    return (__bridge_transfer NSString *)
    CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                            (__bridge CFStringRef)self,
                                            NULL,
                                            (__bridge CFStringRef)@"!*'\"();:@&=+$,/?%#[] ",
                                            kCFStringEncodingUTF8);
}

- (NSString *)URLDecode
{
    return (__bridge_transfer NSString *)
    CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                            (__bridge CFStringRef)self,
                                                            (__bridge CFStringRef)@"",
                                                            kCFStringEncodingUTF8);
}

@end
