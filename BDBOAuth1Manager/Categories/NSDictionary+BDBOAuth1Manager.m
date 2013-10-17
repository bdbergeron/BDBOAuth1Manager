//
//  NSDictionary+BDBOAuth1Manager.m
//
//  Created by Bradley David Bergeron on 9/20/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import "NSDictionary+BDBOAuth1Manager.h"
#import "NSString+BDBOAuth1Manager.h"


#pragma mark -
@implementation NSDictionary (BDBOAuth1Manager)

+ (instancetype)dictionaryFromQueryString:(NSString *)queryString
{
    NSArray *components = [queryString componentsSeparatedByString:@"&"];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (NSString *component in components)
    {
        NSArray *keyValue = [component componentsSeparatedByString:@"="];
        dictionary[[keyValue[0] URLDecode]] = [keyValue[1] URLDecode];
    }
    return dictionary;
}

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
