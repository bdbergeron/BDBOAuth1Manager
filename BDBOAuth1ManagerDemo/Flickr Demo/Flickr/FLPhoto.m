//
//  FLPhoto.m
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

#import "FLPhoto.h"

#pragma mark -
@implementation FLPhoto

- (id)initWithDictionary:(NSDictionary *)photoInfo {
    self = [super init];

    if (self) {
        _photoId = [photoInfo[@"id"] copy];
        _secret  = [photoInfo[@"secret"] copy];

        NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];

        _title = [[photoInfo[@"title"] copy] stringByTrimmingCharactersInSet:whitespace];

        if (photoInfo[@"description"]) {
            _description = [[photoInfo[@"description"][@"_content"] copy] stringByTrimmingCharactersInSet:whitespace];
        }

        if (photoInfo[@"url_t"]) {
            _thumbnailURL = [[NSURL URLWithString:photoInfo[@"url_t"]] copy];
        }

        if (photoInfo[@"url_o"]) {
            _originalURL = [[NSURL URLWithString:photoInfo[@"url_o"]] copy];
        }
    }

    return self;
}

#pragma mark Equality
- (BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }

    if (![object isKindOfClass:[FLPhoto class]]) {
        return NO;
    } else {
        return [self isEqualToPhoto:(FLPhoto *)object];
    }
}

- (BOOL)isEqualToPhoto:(FLPhoto *)photo {
    if (!photo) {
        return NO;
    }

    BOOL equalId = (!self.photoId && !photo.photoId) || [self.photoId isEqualToString:photo.photoId];
    BOOL equalSecret  = (!self.secret && !photo.secret) || [self.secret isEqualToString:photo.secret];

    BOOL equalTitle = (!self.title && !photo.title) || [self.title isEqualToString:photo.title];
    BOOL equalDescription = (!self.description && !photo.description) || [self.description isEqualToString:photo.description];

    BOOL equalThumbnailURL = (!self.thumbnailURL && !photo.thumbnailURL) || [self.thumbnailURL isEqual:photo.thumbnailURL];
    BOOL equalOriginalURL = (!self.originalURL && !photo.originalURL) || [self.originalURL isEqual:photo.originalURL];

    return (equalId && equalSecret
            && equalTitle && equalDescription
            && equalThumbnailURL && equalOriginalURL);
}

- (NSUInteger)hash {
    return (self.photoId.hash ^ self.secret.hash
            ^ self.title.hash ^ self.description.hash
            ^ self.thumbnailURL.hash ^ self.originalURL.hash);
}

@end
