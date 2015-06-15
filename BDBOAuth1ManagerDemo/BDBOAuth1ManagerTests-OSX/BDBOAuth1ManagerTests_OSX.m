//
//  BDBOAuth1ManagerTests_OSX.m
//  BDBOAuth1ManagerTests-OSX
//
//  Created by Shawn Kim on 6/9/15.
//  Copyright (c) 2015 Bradley David Bergeron. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "BDBOAuth1RequestSerializer.h"

@interface BDBOAuth1RequestSerializer ()

- (NSString *)OAuthSignatureForMethod:(NSString *)method
                            URLString:(NSString *)URLString
                           parameters:(NSDictionary *)parameters
                                error:(NSError *__autoreleasing *)error;

@end

@interface BDBOAuth1ManagerTests_OSX : XCTestCase

@end

@implementation BDBOAuth1ManagerTests_OSX

// Test cases from http://wiki.oauth.net/w/page/12238556/TestCases

- (void) testOAuth1HMACSHA1Signatures {
    NSString *expectedSignature = @"tR3+Ty81lMeYAr/Fid0kMTYa/WM=";

    NSString *service = @"http://photos.example.net";
    NSString *path = @"photos";

    NSString *consumerKey = @"dpf43f3p2l4k3l03";
    NSString *consumerSecret = @"kd94hf93k423kf44";

    NSString *tokenKey = @"nnch734d00sl2jdk";
    NSString *tokenSecret = @"pfkkdhi9sl3r4s00";

    /*Expected base string:

     GET&http%3A%2F%2Fphotos.example.net%2Fphotos&file%3Dvacation.jpg%26oauth_consumer_key%3Ddpf43f3p2l4k3l03%26oauth_nonce%3Dkllo9940pd9333jh%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1191242096%26oauth_token%3Dnnch734d00sl2jdk%26oauth_version%3D1.0%26size%3Doriginal
     */
    NSDictionary *parameters = @{ @"oauth_signature_method": @"HMAC-SHA1",
                                  @"oauth_version": @"1.0",
                                  @"oauth_consumer_key": consumerKey,
                                  @"oauth_token": tokenKey,
                                  @"oauth_timestamp": @"1191242096",
                                  @"oauth_nonce": @"kllo9940pd9333jh",
                                  @"file": @"vacation.jpg",
                                  @"size": @"original" };

    BDBOAuth1RequestSerializer *serializer = [BDBOAuth1RequestSerializer serializerForService:service withConsumerKey:consumerKey consumerSecret:consumerSecret];
    [serializer setValue:[BDBOAuth1Credential credentialWithToken:tokenKey secret:tokenSecret expiration:[NSDate dateWithTimeIntervalSinceNow:3600]] forKey:NSStringFromSelector(@selector(accessToken))];

    NSError *error;
    NSString *signature = [serializer OAuthSignatureForMethod:@"GET" URLString:[NSString stringWithFormat:@"%@/%@", service, path] parameters:parameters error:&error];
    XCTAssertEqualObjects(signature, expectedSignature, @"Computed OAuth signature does not match expected signature");
}

@end
