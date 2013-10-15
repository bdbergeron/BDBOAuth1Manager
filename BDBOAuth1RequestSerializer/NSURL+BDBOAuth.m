//
//  NSURL+BDBOAuth.m
//
//  Created by Bradley David Bergeron on 9/19/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import "NSDictionary+BDBOAuth.h"
#import "NSString+BDBOAuth.h"
#import "NSURL+BDBOAuth.h"


#pragma mark -
@implementation NSURL (BDBOAuth)

- (NSURL *)URLByAppendingParameters:(NSDictionary *)parameters
{
    NSMutableString *query = [self.query mutableCopy];

    if (!query)
        query = [NSMutableString stringWithString:@""];

    NSArray *parameterNames = parameters.allKeys;
    parameterNames = [parameterNames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    for (NSString *parameterName in parameterNames)
    {
        id value = parameters[parameterName];
        NSAssert3([parameterName isKindOfClass:[NSString class]],
                  @"Got '%@' of type %@ as key for parameter with value '%@'. Expected an NSString.",
                  parameterName,
                  NSStringFromClass([parameterName class]),
                  value);

        if (![value isKindOfClass:[NSString class]])
        {
            if ([value respondsToSelector:@selector(stringValue)])
                value = [value stringValue];
            else
                value = [value description];
        }

        if (query.length == 0)
            [query appendFormat:@"%@=%@", [parameterName URLEncode], [value URLEncode]];
        else
            [query appendFormat:@"&%@=%@", [parameterName URLEncode], [value URLEncode]];
    }

    // scheme://username:password@domain:port/path?query_string#fragment_id

    // Chop off query and fragment from absoluteString, then add new query and put back fragment
    NSString *absoluteString = self.absoluteString;
    NSUInteger endIndex = absoluteString.length;

    if (self.fragment)
    {
        endIndex -= self.fragment.length;
        endIndex--; // The # character
    }

    if (self.query)
    {
        endIndex -= self.query.length;
        endIndex--; // The ? character
    }

    absoluteString = [absoluteString substringToIndex:endIndex];
    absoluteString = [absoluteString stringByAppendingString:@"?"];
    absoluteString = [absoluteString stringByAppendingString:query];
    if (self.fragment)
    {
        absoluteString = [absoluteString stringByAppendingString:@"#"];
        absoluteString = [absoluteString stringByAppendingString:self.fragment];
    }

    return [NSURL URLWithString:absoluteString];
}

- (NSURL *)URLByAppendingParameterName:(NSString *)parameter value:(id)value
{
    return [self URLByAppendingParameters:[NSDictionary dictionaryWithObjectsAndKeys:value, parameter, nil]];
}


- (NSDictionary *)dictionaryFromQueryString
{
    return [NSDictionary dictionaryFromQueryString:self.query];
}

@end