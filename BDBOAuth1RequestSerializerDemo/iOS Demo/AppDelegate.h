//
//  AppDelegate.h
//
//  Created by Bradley Bergeron on 11/10/2013.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AFNetworking.h"


#pragma mark -
@interface AppDelegate : UIResponder
<UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, readonly) AFHTTPRequestSerializer *requestSerializer;

+ (instancetype)sharedDelegate;

@end
