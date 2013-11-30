//
//  FLPhotoset.h
//  BDBOAuth1ManagerDemo
//
//  Created by Bradley Bergeron on 29/11/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import <Foundation/Foundation.h>


#pragma mark -
@interface FLPhotoset : NSObject

@property (nonatomic, copy) NSString *setId;
@property (nonatomic, copy) NSString *primary;
@property (nonatomic, copy) NSString *secret;

@property (nonatomic) NSArray *photos;

@property (nonatomic) NSDate *dateCreated;
@property (nonatomic) NSDate *dateUpdated;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *description;

- (id)initWithDictionary:(NSDictionary *)photosetInfo;

@end
