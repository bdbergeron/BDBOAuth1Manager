//
//  FLClient.h
//  BDBOAuth1ManagerDemo
//
//  Created by Bradley Bergeron on 30/11/13.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import <BDBOAuth1Manager/BDBOAuth1RequestOperationManager.h>
#import <BDBOAuth1Manager/BDBOAuth1SessionManager.h>
#import <Foundation/Foundation.h>

#import "FLPhotoset.h"
#import "FLPhoto.h"


#pragma mark -
@interface FLClient : NSObject

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
+ (instancetype)clientWithAPIKey:(NSString *)apiKey networkManager:(BDBOAuth1SessionManager *)manager;
- (id)initWithAPIKey:(NSString *)apiKey networkManager:(BDBOAuth1SessionManager *)manager;
#else
+ (instancetype)clientWithAPIKey:(NSString *)apiKey networkManager:(BDBOAuth1RequestOperationManager *)manager;
- (id)initWithAPIKey:(NSString *)apiKey networkManager:(BDBOAuth1RequestOperationManager *)manager;
#endif
+ (instancetype)sharedClient;

- (void)getPhotosetsWithCompletion:(void (^)(NSSet *photosets, NSError *error))completion;
- (void)getPhotosInPhotoset:(FLPhotoset *)photoset completion:(void (^)(NSArray *photos, NSError *error))completion;

@end
