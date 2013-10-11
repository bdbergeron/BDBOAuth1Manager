//
//  NSURL+BDBOAuth.h
//
//  Created by Bradley David Bergeron on 9/19/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import <Foundation/Foundation.h>


#pragma mark -
@interface NSURL (BDBOAuth)

- (NSURL *)URLByAppendingParameters:(NSDictionary *)parameters;
- (NSURL *)URLByAppendingParameterName:(NSString *)parameter value:(id)value;

- (NSDictionary *)dictionaryFromQueryString;

@end
