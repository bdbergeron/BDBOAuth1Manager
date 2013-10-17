//
//  NSDictionary+BDBOAuth1Manager.h
//
//  Created by Bradley David Bergeron on 9/20/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import <Foundation/Foundation.h>


#pragma mark -
@interface NSDictionary (BDBOAuth1Manager)

+ (instancetype)dictionaryFromQueryString:(NSString *)queryString;

- (NSString *)queryStringFromDictionary;

@end
