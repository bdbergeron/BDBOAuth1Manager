//
//  FLPhoto.m
//  BDBOAuth1ManagerDemo
//
//  Created by Bradley Bergeron on 29/11/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import "FLPhoto.h"


#pragma mark -
@implementation FLPhoto

- (id)initWithDictionary:(NSDictionary *)photoInfo
{
    self = [super init];
    if (self)
    {
        _photoId = photoInfo[@"id"];
        _secret  = photoInfo[@"secret"];

        _title = [photoInfo[@"title"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        if (photoInfo[@"description"])
            _description = [photoInfo[@"description"][@"_content"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        if (photoInfo[@"url_t"])
            _thumbnailURL = [NSURL URLWithString:photoInfo[@"url_t"]];

        if (photoInfo[@"url_o"])
            _originalURL = [NSURL URLWithString:photoInfo[@"url_o"]];
    }
    return self;
}

#pragma mark Equality
- (BOOL)isEqualToPhoto:(FLPhoto *)photo
{
    if (!photo)
        return NO;

    BOOL haveEqualIds = (!self.photoId && !photo.photoId) || [self.photoId isEqualToString:photo.photoId];
    BOOL haveEqualSecrets  = (!self.secret && !photo.secret) || [self.secret isEqualToString:photo.secret];

    return haveEqualIds && haveEqualSecrets;
}

- (BOOL)isEqual:(id)object
{
    if (object == self)
        return YES;
    if (![object isKindOfClass:[FLPhoto class]])
        return NO;
    else
        return [self isEqualToPhoto:(FLPhoto *)object];
}

- (NSUInteger)hash
{
    return self.photoId.hash ^ self.secret.hash;
}

@end
