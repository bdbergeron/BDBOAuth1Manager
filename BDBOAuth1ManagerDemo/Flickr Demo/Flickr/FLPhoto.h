//
//  FLPhoto.h
//  BDBOAuth1ManagerDemo
//
//  Created by Bradley Bergeron on 29/11/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import <Foundation/Foundation.h>


#pragma mark -
@interface FLPhoto : NSObject

@property (nonatomic, copy) NSString *photoId;
@property (nonatomic, copy) NSString *secret;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *description;

@property (nonatomic) NSURL *thumbnailURL;
@property (nonatomic) NSURL *originalURL;

- (id)initWithDictionary:(NSDictionary *)photoInfo;

@end
