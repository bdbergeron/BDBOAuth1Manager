//
//  FLClient.m
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

#import "FLClient.h"


static NSString * const kFLClientErrorDomain = @"com.bradbergeron.bdboauth.flickr.error";

#pragma mark -
@interface FLClient ()

@property (nonatomic, strong) NSString *apiKey;

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
@property (nonatomic) BDBOAuth1SessionManager *networkManager;
#else
@property (nonatomic) BDBOAuth1RequestOperationManager *networkManager;
#endif

- (NSDictionary *)defaultRequestParameters;

@end

#pragma mark -
@implementation FLClient

static FLClient * _sharedClient = nil;

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
+ (instancetype)clientWithAPIKey:(NSString *)apiKey networkManager:(BDBOAuth1SessionManager *)manager {
    return [[[self class] alloc] initWithAPIKey:apiKey networkManager:manager];
}

- (id)initWithAPIKey:(NSString *)apiKey networkManager:(BDBOAuth1SessionManager *)manager {
    self = [super init];

    if (self) {
        _apiKey = apiKey;
        _networkManager = manager;
        _sharedClient = self;
    }

    return self;
}

#else
+ (instancetype)clientWithAPIKey:(NSString *)apiKey networkManager:(BDBOAuth1RequestOperationManager *)manager {
    return [[[self class] alloc] initWithAPIKey:apiKey networkManager:manager];
}

- (id)initWithAPIKey:(NSString *)apiKey networkManager:(BDBOAuth1RequestOperationManager *)manager {
    self = [super init];

    if (self) {
        _apiKey = apiKey;
        _networkManager = manager;
        _sharedClient = self;
    }

    return self;
}

#endif

+ (instancetype)sharedClient {
    NSAssert(_sharedClient, @"FLClient not initialized. Use [FLClient clientWithAPIKey:].");

    return _sharedClient;
}

- (NSDictionary *)defaultRequestParameters {
    return @{@"api_key":        self.apiKey,
             @"format":         @"json",
             @"nojsoncallback": @(1)};
}

- (void)getPhotosetsWithCompletion:(void (^)(NSSet *, NSError *))completion {
    NSAssert(self.apiKey, @"API key not set.");

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self defaultRequestParameters]];
    params[@"method"] = @"flickr.photosets.getList";

    #if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    [self.networkManager GET:@"rest" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = responseObject;

            if ([response[@"stat"] isEqualToString:@"ok"]) {
                response = response[@"photosets"];
                NSMutableSet *photosets = [NSMutableSet set];

                for (NSDictionary *setInfo in response[@"photoset"]) {
                    FLPhotoset *set = [[FLPhotoset alloc] initWithDictionary:setInfo];
                    [photosets addObject:set];
                }
                completion(photosets, nil);
            } else {
                NSError *error = [NSError errorWithDomain:kFLClientErrorDomain
                                                     code:1100
                                                 userInfo:@{NSLocalizedDescriptionKey:response[@"message"]}];
                completion(nil, error);
            }
        } else {
            NSError *error = [NSError errorWithDomain:kFLClientErrorDomain
                                                 code:1000
                                             userInfo:@{NSLocalizedDescriptionKey:@"Unexpected response received from Flickr API."}];
            completion(nil, error);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil, error);
    }];

    #else
    [self.networkManager GET:@"rest" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = responseObject;

            if ([response[@"stat"] isEqualToString:@"ok"]) {
                response = response[@"photosets"];
                NSMutableSet *photosets = [NSMutableSet set];

                for (NSDictionary *setInfo in response[@"photoset"]) {
                    FLPhotoset *set = [[FLPhotoset alloc] initWithDictionary:setInfo];
                    [photosets addObject:set];
                }
                completion(photosets, nil);
            } else {
                NSError *error = [NSError errorWithDomain:kFLClientErrorDomain
                                                     code:1100
                                                 userInfo:@{NSLocalizedDescriptionKey:response[@"message"]}];
                completion(nil, error);
            }
        } else {
            NSError *error = [NSError errorWithDomain:kFLClientErrorDomain
                                                 code:1000
                                             userInfo:@{NSLocalizedDescriptionKey:@"Unexpected response received from Flickr API."}];
            completion(nil, error);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];

    #endif
}

- (void)getPhotosInPhotoset:(FLPhotoset *)photoset completion:(void (^)(NSArray *, NSError *))completion {
    NSAssert(self.apiKey, @"API key not set.");

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self defaultRequestParameters]];
    params[@"method"] = @"flickr.photosets.getPhotos";
    params[@"photoset_id"] = photoset.setId;
    params[@"extras"] = @"url_t, url_o, description";

    #if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    [self.networkManager GET:@"rest" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = responseObject;

            if ([response[@"stat"] isEqualToString:@"ok"]) {
                response = response[@"photoset"];
                NSMutableArray *photos = [NSMutableArray array];

                for (NSDictionary *photoInfo in response[@"photo"]) {
                    FLPhoto *photo = [[FLPhoto alloc] initWithDictionary:photoInfo];
                    [photos addObject:photo];
                }
                completion(photos, nil);
            } else {
                NSError *error = [NSError errorWithDomain:kFLClientErrorDomain
                                                     code:1100
                                                 userInfo:@{NSLocalizedDescriptionKey:response[@"message"]}];
                completion(nil, error);
            }
        } else {
            NSError *error = [NSError errorWithDomain:kFLClientErrorDomain
                                                 code:1000
                                             userInfo:@{NSLocalizedDescriptionKey:@"Unexpected response received from Flickr API."}];
            completion(nil, error);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil, error);
    }];

    #else
    [self.networkManager GET:@"rest" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = responseObject;

            if ([response[@"stat"] isEqualToString:@"ok"]) {
                response = response[@"photoset"];
                NSMutableArray *photos = [NSMutableArray array];

                for (NSDictionary *photoInfo in response[@"photo"]) {
                    FLPhoto *photo = [[FLPhoto alloc] initWithDictionary:photoInfo];
                    [photos addObject:photo];
                }
                completion(photos, nil);
            } else {
                NSError *error = [NSError errorWithDomain:kFLClientErrorDomain
                                                     code:1100
                                                 userInfo:@{NSLocalizedDescriptionKey:response[@"message"]}];
                completion(nil, error);
            }
        } else {
            NSError *error = [NSError errorWithDomain:kFLClientErrorDomain
                                                 code:1000
                                             userInfo:@{NSLocalizedDescriptionKey:@"Unexpected response received from Flickr API."}];
            completion(nil, error);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];

    #endif
}

@end
