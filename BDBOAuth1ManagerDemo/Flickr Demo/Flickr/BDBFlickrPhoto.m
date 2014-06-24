//
//  BDBFlickrPhoto.m
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

#import "BDBFlickrPhoto.h"

#pragma mark -
@implementation BDBFlickrPhoto

- (id)initWithDictionary:(NSDictionary *)photoInfo {
    self = [super init];

    if (self) {
        _photoId = [photoInfo[@"id"] copy];
        _title   = [[photoInfo[@"title"] copy] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        if (photoInfo[@"url_t"]) {
            _thumbnailURL = [NSURL URLWithString:photoInfo[@"url_t"]];
        }

        if (photoInfo[@"url_o"]) {
            _originalURL = [NSURL URLWithString:photoInfo[@"url_o"]];
        }
    }

    return self;
}

#pragma mark Equality
- (BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }

    if (![object isKindOfClass:[BDBFlickrPhoto class]]) {
        return NO;
    } else {
        return [self isEqualToPhoto:(BDBFlickrPhoto *)object];
    }
}

- (BOOL)isEqualToPhoto:(BDBFlickrPhoto *)photo {
    if (!photo) {
        return NO;
    }

    BOOL equalId = (!self.photoId && !photo.photoId) || [self.photoId isEqualToString:photo.photoId];
    BOOL equalTitle = (!self.title && !photo.title) || [self.title isEqualToString:photo.title];

    BOOL equalThumbnailURL = (!self.thumbnailURL && !photo.thumbnailURL) || [self.thumbnailURL isEqual:photo.thumbnailURL];
    BOOL equalOriginalURL = (!self.originalURL && !photo.originalURL) || [self.originalURL isEqual:photo.originalURL];

    return (equalId && equalTitle && equalThumbnailURL && equalOriginalURL);
}

- (NSUInteger)hash {
    return (self.photoId.hash ^ self.title.hash ^ self.thumbnailURL.hash ^ self.originalURL.hash);
}

@end
