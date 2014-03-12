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
        _photoId = photoInfo[@"id"];
        _secret  = photoInfo[@"secret"];

        _title = [photoInfo[@"title"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        if (photoInfo[@"description"]) {
            _description = [photoInfo[@"description"][@"_content"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }

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
- (BOOL)isEqualToPhoto:(FLPhoto *)photo {
    if (!photo) {
        return NO;
    }

    BOOL haveEqualIds = (!self.photoId && !photo.photoId) || [self.photoId isEqualToString:photo.photoId];
    BOOL haveEqualSecrets  = (!self.secret && !photo.secret) || [self.secret isEqualToString:photo.secret];

    return haveEqualIds && haveEqualSecrets;
}

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

- (NSUInteger)hash {
    return self.photoId.hash ^ self.secret.hash;
}

@end
