//
//  BDBOAuth1ManagerTests.h
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

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "BDBOAuth1RequestSerializer.h"

@interface BDBOAuth1RequestSerializer ()

- (NSString *)OAuthSignatureForMethod:(NSString *)method
                            URLString:(NSString *)URLString
                           parameters:(NSDictionary *)parameters
                                error:(NSError *__autoreleasing *)error;

@end

@interface BDBOAuth1ManagerTests_iOS : XCTestCase

@end

@implementation BDBOAuth1ManagerTests_iOS

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

- (void) testOAuth1RSASHA1Signatures {
    NSString *expectedSignature = @"jvTp/wX1TYtByB1m+Pbyo0lnCOLIsyGCH7wke8AUs3BpnwZJtAuEJkvQL2/9n4s5wUmUl4aCI4BwpraNx4RtEXMe5qg5T1LVTGliMRpKasKsW//e+RinhejgCuzoH26dyF8iY2ZZ/5D1ilgeijhV/vBka5twt399mXwaYdCwFYE=";

    NSString *service = @"http://photos.example.net";
    NSString *path = @"photos";

    /* Base64 encoded PKCS12 identity generated from:
     
     PKCS8 Private Key:

     -----BEGIN PRIVATE KEY-----
     MIICdgIBADANBgkqhkiG9w0BAQEFAASCAmAwggJcAgEAAoGBALRiMLAh9iimur8V
     A7qVvdqxevEuUkW4K+2KdMXmnQbG9Aa7k7eBjK1S+0LYmVjPKlJGNXHDGuy5Fw/d
     7rjVJ0BLB+ubPK8iA/Tw3hLQgXMRRGRXXCn8ikfuQfjUS1uZSatdLB81mydBETlJ
     hI6GH4twrbDJCR2Bwy/XWXgqgGRzAgMBAAECgYBYWVtleUzavkbrPjy0T5FMou8H
     X9u2AC2ry8vD/l7cqedtwMPp9k7TubgNFo+NGvKsl2ynyprOZR1xjQ7WgrgVB+mm
     uScOM/5HVceFuGRDhYTCObE+y1kxRloNYXnx3ei1zbeYLPCHdhxRYW7T0qcynNmw
     rn05/KO2RLjgQNalsQJBANeA3Q4Nugqy4QBUCEC09SqylT2K9FrrItqL2QKc9v0Z
     zO2uwllCbg0dwpVuYPYXYvikNHHg+aCWF+VXsb9rpPsCQQDWR9TT4ORdzoj+Nccn
     qkMsDmzt0EfNaAOwHOmVJ2RVBspPcxt5iN4HI7HNeG6U5YsFBb+/GZbgfBT3kpNG
     WPTpAkBI+gFhjfJvRw38n3g/+UeAkwMI2TJQS4n8+hid0uus3/zOjDySH3XHCUno
     cn1xOJAyZODBo47E+67R4jV1/gzbAkEAklJaspRPXP877NssM5nAZMU0/O/NGCZ+
     3jPgDUno6WbJn5cqm8MqWhW1xGkImgRk+fkDBquiq4gPiT898jusgQJAd5Zrr6Q8
     AO/0isr/3aa6O6NLQxISLKcPDk2NOccAfS/xOtfOz4sJYM3+Bs4Io9+dZGSDCA54
     Lw03eHTNQghS0A==
     -----END PRIVATE KEY-----
     
     Certificate:

     -----BEGIN CERTIFICATE-----
     MIIBpjCCAQ+gAwIBAgIBATANBgkqhkiG9w0BAQUFADAZMRcwFQYDVQQDDA5UZXN0
     IFByaW5jaXBhbDAeFw03MDAxMDEwODAwMDBaFw0zODEyMzEwODAwMDBaMBkxFzAV
     BgNVBAMMDlRlc3QgUHJpbmNpcGFsMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKB
     gQC0YjCwIfYoprq/FQO6lb3asXrxLlJFuCvtinTF5p0GxvQGu5O3gYytUvtC2JlY
     zypSRjVxwxrsuRcP3e641SdASwfrmzyvIgP08N4S0IFzEURkV1wp/IpH7kH41Etb
     mUmrXSwfNZsnQRE5SYSOhh+LcK2wyQkdgcMv11l4KoBkcwIDAQABMA0GCSqGSIb3
     DQEBBQUAA4GBAGZLPEuJ5SiJ2ryq+CmEGOXfvlTtEL2nuGtr9PewxkgnOjZpUy+d
     4TvuXJbNQc8f4AMWL/tO9w0Fk80rWKp9ea8/df4qMq5qlFWlx6yOLQxumNOmECKb
     WpkUQDIDJEoFUzKMVuJf4KO/FJ345+BNLGgbJ6WujreoM1X/gYfdnJ/J
     -----END CERTIFICATE-----
     
     openssl pkcs12 -export -inkey priv.key -in cert.cer -out id.p12 | base64
     */
    NSString *pkcs12IdentityString = @"MIIFoQIBAzCCBWcGCSqGSIb3DQEHAaCCBVgEggVUMIIFUDCCAk8GCSqGSIb3DQEHBqCCAkAwggI8AgEAMIICNQYJKoZIhvcNAQcBMBwGCiqGSIb3DQEMAQYwDgQIWarzGOduQfkCAggAgIICCP3hmzrKg7zlCEKiMyW7GukMNf5uzvfCe387u565Q3CXWBvt3SYUOV9/EDPe8LVlckhyWe13UxyV1mA7wu0J6GXx2GDG1ejUIXVNNnN7BuOsHaSdvbtcEmIDehw5ztTPsyI9CIrqcWBYuT3zbiooY4IMjQIM/sxU/xT09aG4YU3Mp0EBiXFYIlt/p3HdWMbFP6rPXmxzV3zuu8IxTyNvSxdjn7y7YRrOsYq2E1Ir0EQ6J4cGolpE7z/YFG/ClCv4WMhKddCe2lFepBZ/ZXslw4baDNQTOAsQvorbwBQFH2M5X1Esm/99aoeO54kf0I79M0agtxQblluv0AgCJXDt/amT0Gw2kIx42bV9SAPnHSTUZj5TK/NNtN1ioDBkDmlO6E/LocxjQuJhEzyDDOEug9/GeKTZKk8z0AHhyRS7YtYU6yWyMAXTiXCBtH499SR/DktV4qgoTxUVWVX0Ww2JEbVjYGF7D1bhG6+/SqC1PXPDW56g9EdxMsHQ6UiLVypIeH2PgHlKowW7S6rDP5XCX0WP7gynA5QUJu+vR21ofzBnmMqouBPefHNIafChLpZ3Yf1hKPzTM2O54C5hIXT4ZZPEIH0pkN/c5WxsCY7C+Twlg1p+iCJjmLjPHrfWKF6ZVXfopyM0q0YZnaEe/a2dwWca4dFaYR1Ye7WmEpikUdIrcs1aBEPlvA0wggL5BgkqhkiG9w0BBwGgggLqBIIC5jCCAuIwggLeBgsqhkiG9w0BDAoBAqCCAqYwggKiMBwGCiqGSIb3DQEMAQMwDgQIEmugo5LoJ4UCAggABIICgOaYelT606qdQ73fYCzCGJd/zRsIIsV1lxAUXLt5eGaMO8cpQfL9l2kMmUCxpGtBVGvuvejcDJUlkjxxqmJMY5519Nz2Y6ESNGU3aX7sqCnZV7SXBpIlVrdpf+VxT0e94Pf2vsan7qNCrKpcWsWDP5ZKiBaeDi2ZjYjZIyQ7biMIyBjOitAf+w4u3hOV48d7JaCeKVAGPi4faE6EcQ6J/sPWy5asRXDhnRFdzDWz/ziXE2IgLZrrNs3Yp+qSWIg5gsOn9oCwLKIIfyxC59V7mzYUJ0q+5NsvoduX8ou02v2DCwn3aRDd2Qz++J/kk1ad6tn6EjmOk+sLKx66ztw2bGNWcBWfbAOG2QjRrp+b8A7w1pZ4Zt+qVTWGuRKnz80Za2BZx94Ml7K2GLYBCcZRBCaQtmgHQYBXx6nRfRwfqQpfNflColMZqccTcgE+/8NV8idMW6F20L51xp70uNimNTAoIVpgmGlRhNK/0DGaAVIcPuw/hXdDHlXnyW4TzhoRrnZzaPO53cmQQvvb3BpdH5Klo6I26ZXDQVt6nVZ3Yk1PUO9lVdOyFo0aWP7wnympELWu/7L9z8lwGQaa+m+IqlKsvP2q4iBQs6HNS0ssTHpXFprmeaRyfwZNoC2Uiq3gAjbn4VujgBpKpFoR7Yxh792iwq2NCtiyNhuHRpX3Hs/vMxRGuEqGLqN4bExwlsnmfk8rUW9pNLzucPACTCVf10t2oqi+Sv0dMuxQa2e5OlMiKp1D+GAeF9usNAnTOE3vmK4bCaLUQ9769xztAeKkQJ3zufBdRYB9jEIi2B5X89x8l4csGdHr2A8KAD0vJlLEXisUQdN0XkBMMYWCp/NtFeAxJTAjBgkqhkiG9w0BCRUxFgQUyxy3KzcjoJDSIjCFZZpzt9s8OvEwMTAhMAkGBSsOAwIaBQAEFO8/JDF+DcwTHzx7kp45U3udWoI/BAgQAMdvRAUJmwICCAA=";

    NSString *consumerKey = @"dpf43f3p2l4k3l03";

    /* Expected base string:

     GET&http%3A%2F%2Fphotos.example.net%2Fphotos&file%3Dvacaction.jpg%26oauth_consumer_key%3Ddpf43f3p2l4k3l03%26oauth_nonce%3D13917289812797014437%26oauth_signature_method%3DRSA-SHA1%26oauth_timestamp%3D1196666512%26oauth_version%3D1.0%26size%3Doriginal
     */
    NSDictionary *parameters = @{ @"oauth_signature_method": @"RSA-SHA1",
                                  @"oauth_version": @"1.0",
                                  @"oauth_consumer_key": consumerKey,
                                  @"oauth_timestamp": @"1196666512",
                                  @"oauth_nonce": @"13917289812797014437",
                                  @"file": @"vacaction.jpg",
                                  @"size": @"original" };

    // Extract private key from PKCS12 identity
    CFArrayRef importResults = NULL;
    NSDictionary *options = @{ (__bridge id)kSecImportExportPassphrase: @"" };
    NSData *pkcs12IdentityData = [[NSData alloc] initWithBase64EncodedString:pkcs12IdentityString options:0];
    SecPKCS12Import((__bridge CFDataRef)pkcs12IdentityData, (__bridge CFDictionaryRef)options, &importResults);
    SecIdentityRef identity = (SecIdentityRef)CFDictionaryGetValue(CFArrayGetValueAtIndex(importResults, 0),
                                                                   kSecImportItemIdentity);
    SecKeyRef RSAPrivateKey = NULL;
    SecIdentityCopyPrivateKey(identity, &RSAPrivateKey);

    BDBOAuth1RequestSerializer *serializer = [BDBOAuth1RequestSerializer serializerForService:service withConsumerKey:consumerKey RSAPrivateKey:RSAPrivateKey];
    NSString *signature = [serializer OAuthSignatureForMethod:@"GET" URLString:[NSString stringWithFormat:@"%@/%@", service, path] parameters:parameters error:nil];
    serializer = nil;
    XCTAssertEqualObjects(signature, expectedSignature, @"Computed OAuth signature does not match expected signature");
}

@end

