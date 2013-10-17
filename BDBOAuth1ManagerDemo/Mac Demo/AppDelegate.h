//
//  AppDelegate.h
//  BDBOAuth1RequestSerializerDemo
//
//  Created by Bradley Bergeron on 11/10/2013.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "AFNetworking.h"
#import "BDBOAuth1RequestOperationManager.h"


#pragma mark -
@interface AppDelegate : NSObject
<NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

#ifdef __MAC_10_10
@property (nonatomic, readonly) BDBOAuth1SessionManager *networkManager;
#else
@property (nonatomic, readonly) BDBOAuth1RequestOperationManager *networkManager;
#endif

@property (nonatomic, assign, readonly, getter = isAuthorized) BOOL authorized;

#pragma mark Initialization
+ (instancetype)sharedDelegate;

#pragma mark OAuth
- (void)authorize;

@end
