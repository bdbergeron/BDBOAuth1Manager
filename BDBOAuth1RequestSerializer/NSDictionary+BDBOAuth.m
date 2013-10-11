//
//  NSDictionary+BDBOAuth.m
//
//  Created by Bradley David Bergeron on 9/20/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import "NSDictionary+BDBOAuth.h"
#import "NSString+BDBOAuth.h"


#pragma mark -
@implementation NSDictionary (BDBOAuth)

- (NSString *)queryStringFromDictionary
{
    NSMutableArray *paramArray = [NSMutableArray array];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *param = [NSString stringWithFormat:@"%@=%@", [key URLEncode], [obj URLEncode]];
        [paramArray addObject:param];
    }];
    return [paramArray componentsJoinedByString:@"&"];
}

@end
