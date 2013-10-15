//
//  NSDictionary+BDBOAuth.h
//
//  Created by Bradley David Bergeron on 9/20/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import <Foundation/Foundation.h>


#pragma mark -
@interface NSDictionary (BDBOAuth)

+ (instancetype)dictionaryFromQueryString:(NSString *)queryString;

- (NSString *)queryStringFromDictionary;

@end
