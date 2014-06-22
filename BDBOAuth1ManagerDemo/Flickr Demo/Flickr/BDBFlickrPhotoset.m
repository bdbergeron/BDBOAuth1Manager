//
//  BDBFlickrPhotoset.m
//
//  Copyright (c) 2014 Bradley David Bergeron
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

#import "BDBFlickrPhotoset.h"

#pragma mark -
@implementation BDBFlickrPhotoset

- (id)initWithDictionary:(NSDictionary *)photosetInfo {
    self = [super init];

    if (self) {
        _setId   = [photosetInfo[@"id"] copy];
        _primary = [photosetInfo[@"primary"] copy];
        _secret  = [photosetInfo[@"secret"] copy];

        NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];

        _title = [photosetInfo[@"title"][@"_content"] stringByTrimmingCharactersInSet:whitespace];
        _description = [photosetInfo[@"description"][@"_content"] stringByTrimmingCharactersInSet:whitespace];

        _dateCreated = [NSDate dateWithTimeIntervalSince1970:[photosetInfo[@"date_create"] integerValue]];
        _dateUpdated = [NSDate dateWithTimeIntervalSince1970:[photosetInfo[@"date_update"] integerValue]];

        _photos = [NSArray array];
    }

    return self;
}

#pragma mark Equivalency
- (BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }

    if (![object isKindOfClass:[BDBFlickrPhotoset class]]) {
        return NO;
    } else {
        return [self isEqualToPhotoset:(BDBFlickrPhotoset *)object];
    }
}

- (BOOL)isEqualToPhotoset:(BDBFlickrPhotoset *)photoset {
    if (!photoset) {
        return NO;
    }

    BOOL equalId = (!self.setId && !photoset.setId) || [self.setId isEqualToString:photoset.setId];
    BOOL equalPrimary = (!self.primary && !photoset.primary) || [self.primary isEqualToString:photoset.primary];
    BOOL equalSecret = (!self.secret && !photoset.secret) || [self.secret isEqualToString:photoset.secret];

    BOOL equalTitle = (!self.title && !photoset.title) || [self.title isEqualToString:photoset.title];
    BOOL equalDescription = (!self.description && !photoset.description) || [self.description isEqualToString:photoset.description];

    BOOL equalDateCreated = [self.dateCreated isEqualToDate:photoset.dateCreated];
    BOOL equalDateUpdated = [self.dateUpdated isEqualToDate:photoset.dateUpdated];

    BOOL samePhotos = (!self.photos && !photoset.photos) || [self.photos isEqualToArray:photoset.photos];

    return (equalId && equalPrimary && equalSecret
            && equalTitle && equalDescription
            && equalDateCreated && equalDateUpdated
            && samePhotos);
}

- (NSUInteger)hash {
    return (self.setId.hash ^ self.primary.hash ^ self.secret.hash
            ^ self.title.hash ^ self.description.hash
            ^ self.dateCreated.hash ^ self.dateUpdated.hash
            ^ self.photos.hash);
}

@end
