//
//  NSString+BDBOAuth1Manager.h
//
//  Copyright (c) 2013-2014 Bradley David Bergeron
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

#import <Foundation/Foundation.h>


/**
 *  Additions to NSString.
 */
#pragma mark -
@interface NSString (BDBOAuth1Manager)

/**
 *  ---------------------------------------------------------------------------------------
 * @name URL Encoding/Decoding
 *  ---------------------------------------------------------------------------------------
 */
#pragma mark URL Encoding/Decoding

/**
 *  Returns a properly URL-decoded representation of the given string.
 *
 *  See http://cybersam.com/ios-dev/proper-url-percent-encoding-in-ios for more details.
 *
 *  @return URL-decoded string
 */
- (NSString *)bdb_URLDecode;

/**
 *  Returns a properly URL-encoded representation of the given string.
 *
 *  See http://cybersam.com/ios-dev/proper-url-percent-encoding-in-ios for more details.
 *
 *  @return URL-encoded string
 */

- (NSString *)bdb_URLEncode;

@end
