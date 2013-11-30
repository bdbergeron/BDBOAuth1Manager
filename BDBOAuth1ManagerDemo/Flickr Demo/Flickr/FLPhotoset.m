//
//  FLPhotoset.m
//  BDBOAuth1ManagerDemo
//
//  Created by Bradley Bergeron on 29/11/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import "FLPhotoset.h"


#pragma mark -
@implementation FLPhotoset

- (id)initWithDictionary:(NSDictionary *)photosetInfo
{
    self = [super init];
    if (self)
    {
        _setId   = photosetInfo[@"id"];
        _primary = photosetInfo[@"primary"];
        _secret  = photosetInfo[@"secret"];

        _photos = [NSArray array];

        _dateCreated = [NSDate dateWithTimeIntervalSince1970:[photosetInfo[@"date_create"] integerValue]];
        _dateUpdated = [NSDate dateWithTimeIntervalSince1970:[photosetInfo[@"date_update"] integerValue]];

        _title = [photosetInfo[@"title"][@"_content"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        _description = [photosetInfo[@"description"][@"_content"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return self;
}

#pragma mark Equivalency
- (BOOL)isEqualToPhotoset:(FLPhotoset *)album
{
    if (!album)
        return NO;

    BOOL haveEqualTitles = (!self.title && !album.title) || [self.title isEqualToString:album.title];
    BOOL haveSamePhotos = (!self.photos && !album.photos) || [self.photos isEqualToArray:album.photos];

    return haveEqualTitles && haveSamePhotos;
}

- (BOOL)isEqual:(id)object
{
    if (object == self)
        return YES;
    if (![object isKindOfClass:[FLPhotoset class]])
        return NO;
    else
        return [self isEqualToPhotoset:(FLPhotoset *)object];
}

@end
