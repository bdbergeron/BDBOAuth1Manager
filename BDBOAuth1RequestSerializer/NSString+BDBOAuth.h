//
//  NSString+BDBOAuth.h
//
//  Created by Bradley David Bergeron on 9/14/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import <Foundation/Foundation.h>


#pragma mark -
@interface NSString (BDBOAuth)

#pragma mark Hashing
+ (instancetype)MD5HashForString:(NSString *)string;
- (NSString *)MD5Hash;
+ (instancetype)SHA1HashForString:(NSString *)string;
- (NSString*)SHA1Hash;

#pragma mark Proper URL Encoding/Decoding
- (NSString *)URLEncode;
- (NSString *)URLDecode;

@end
