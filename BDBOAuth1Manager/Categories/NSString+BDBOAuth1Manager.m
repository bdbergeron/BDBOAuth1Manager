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
