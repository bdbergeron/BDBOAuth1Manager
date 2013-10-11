//
//  BDBOAuth1RequestSerializer.h
//
//  Created by Bradley Bergeron on 11/10/2013.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import "AFURLRequestSerialization.h"

#pragma mark -
@interface BDBOAuth1RequestSerializer : AFHTTPRequestSerializer

+ (instancetype)serializerWithConsumerKey:(NSString *)consumerKey
                           consumerSecret:(NSString *)consumerSecret;

@end
