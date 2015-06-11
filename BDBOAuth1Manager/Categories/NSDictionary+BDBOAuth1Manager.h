//
//  NSDictionary+BDBOAuth1Manager.h
//
//  Copyright (c) 2013-2015 Bradley David Bergeron
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
 *  Additions to NSDictionary.
 */
#pragma mark -
@interface NSDictionary (BDBOAuth1Manager)

/**
 *  ---------------------------------------------------------------------------------------
 * @name Query String
 *  ---------------------------------------------------------------------------------------
 */
#pragma mark Query String

/**
 *  Create a dictionary representation of a URL query string.
 *
 *  @param queryString URL query string.
 *
 *  @return Dictionary containing each key-value pair in the query string.
 */
+ (instancetype)bdb_dictionaryFromQueryString:(NSString *)queryString;

/**
 *  Return each key-value pair in the dictionary as a URL query string.
 *
 *  @return URL query string reperesntation of this dictionary.
 */
- (NSString *)bdb_queryStringRepresentation;

@end
