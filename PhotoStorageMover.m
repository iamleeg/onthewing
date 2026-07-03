// SPDX-License-Identifier: AGPL-3.0-or-later
//
// PhotoStorageMover.m - Copies/deletes journal photos in Google Cloud Storage.
// Copyright (C) 2026 Graham Lee
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

#import "PhotoStorageMover.h"
#import "OTWBearerToken.h"
#include <gnutls/gnutls.h>
#include <gnutls/abstract.h>
#include <gnutls/x509.h>

static NSString * const kDefaultAPIBaseURL = @"https://storage.googleapis.com";
static NSString * const kDefaultTokenURI = @"https://oauth2.googleapis.com/token";
static NSString * const kStorageScope = @"https://www.googleapis.com/auth/devstorage.read_write";
static NSString * const kErrorDomain = @"PhotoStorageMoverErrorDomain";

static NSString *PSMURLEncodeObjectName(NSString *name) {
    NSMutableCharacterSet *unreserved = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [unreserved addCharactersInString:@"-._~"];
    NSString *encoded = [name stringByAddingPercentEncodingWithAllowedCharacters:unreserved];
    [unreserved release];
    return encoded;
}

static NSString *PSMBase64URLEncode(NSData *data) {
    NSString *base64 = [data base64EncodedStringWithOptions:0];
    NSMutableString *result = [[base64 mutableCopy] autorelease];
    [result replaceOccurrencesOfString:@"+" withString:@"-" options:0 range:NSMakeRange(0, [result length])];
    [result replaceOccurrencesOfString:@"/" withString:@"_" options:0 range:NSMakeRange(0, [result length])];
    while ([result hasSuffix:@"="]) {
        [result deleteCharactersInRange:NSMakeRange([result length] - 1, 1)];
    }
    return result;
}

// RS256-signs input with a PEM-encoded RSA private key using GnuTLS.
static NSData *PSMRS256Sign(NSData *input, NSString *privateKeyPEM) {
    // gnutls_global_init() is documented as safe to call repeatedly/from
    // multiple threads (internally reference-counted).
    gnutls_global_init();

    NSData *pemData = [privateKeyPEM dataUsingEncoding:NSUTF8StringEncoding];
    gnutls_datum_t keyDatum = { (unsigned char *)[pemData bytes], (unsigned int)[pemData length] };

    gnutls_privkey_t privkey;
    if (gnutls_privkey_init(&privkey) != GNUTLS_E_SUCCESS) {
        return nil;
    }
    if (gnutls_privkey_import_x509_raw(privkey, &keyDatum, GNUTLS_X509_FMT_PEM, NULL, 0) != GNUTLS_E_SUCCESS) {
        gnutls_privkey_deinit(privkey);
        return nil;
    }

    gnutls_datum_t inputDatum = { (unsigned char *)[input bytes], (unsigned int)[input length] };
    gnutls_datum_t sigDatum;
    // GNUTLS_SIGN_RSA_SHA256 signs the SHA-256 digest of inputDatum with
    // PKCS#1 v1.5 padding - exactly what JWT's RS256 requires (not
    // GNUTLS_SIGN_RSA_PSS_SHA256, which is a different padding scheme).
    int signResult = gnutls_privkey_sign_data2(privkey, GNUTLS_SIGN_RSA_SHA256, 0, &inputDatum, &sigDatum);
    gnutls_privkey_deinit(privkey);
    if (signResult != GNUTLS_E_SUCCESS) {
        return nil;
    }

    NSData *result = [NSData dataWithBytes:sigDatum.data length:sigDatum.size];
    gnutls_free(sigDatum.data);
    return result;
}

// Builds and RS256-signs a JWT-bearer assertion for the OAuth2 service-account
// flow (RFC 7523 / Google's variant of it).
static NSString *PSMSignedJWTAssertion(NSString *issuer, NSString *audience, NSString *scope, NSString *privateKeyPEM) {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSDictionary *header = @{ @"alg": @"RS256", @"typ": @"JWT" };
    NSDictionary *claims = @{
        @"iss": issuer,
        @"scope": scope,
        @"aud": audience,
        @"iat": @((long long)now),
        @"exp": @((long long)now + 3600)
    };

    NSData *headerData = [NSJSONSerialization dataWithJSONObject:header options:0 error:NULL];
    NSData *claimsData = [NSJSONSerialization dataWithJSONObject:claims options:0 error:NULL];
    if (headerData == nil || claimsData == nil) {
        return nil;
    }

    NSString *signingInput = [NSString stringWithFormat:@"%@.%@", PSMBase64URLEncode(headerData), PSMBase64URLEncode(claimsData)];
    NSData *signature = PSMRS256Sign([signingInput dataUsingEncoding:NSUTF8StringEncoding], privateKeyPEM);
    if (signature == nil) {
        return nil;
    }

    return [NSString stringWithFormat:@"%@.%@", signingInput, PSMBase64URLEncode(signature)];
}

@interface PSMURLConnectionTransport : NSObject <PhotoStorageMoverTransport>
@end

@implementation PSMURLConnectionTransport
- (NSData *)sendRequest:(NSURLRequest *)request
                response:(NSURLResponse **)response
                   error:(NSError **)error {
    return [NSURLConnection sendSynchronousRequest:request returningResponse:response error:error];
}
@end

@implementation PhotoStorageMover

- (id)init {
    NSDictionary *env = [[NSProcessInfo processInfo] environment];
    NSString *bucket = [env objectForKey:@"GCS_BUCKET"];
    NSString *apiBaseURL = [env objectForKey:@"GCS_API_BASE_URL"];
    NSString *keyPath = [env objectForKey:@"GCS_SERVICE_ACCOUNT_KEY_PATH"];
    id<PhotoStorageMoverTransport> transport = [[[PSMURLConnectionTransport alloc] init] autorelease];

    return [self initWithBucket:bucket
                      apiBaseURL:apiBaseURL
           serviceAccountKeyPath:keyPath
                       transport:transport];
}

- (id)initWithBucket:(NSString *)bucket
          apiBaseURL:(NSString *)apiBaseURL
serviceAccountKeyPath:(NSString *)serviceAccountKeyPath
           transport:(id<PhotoStorageMoverTransport>)transport {
    self = [super init];
    if (self) {
        _bucket = [bucket copy];
        _apiBaseURL = [(apiBaseURL.length > 0 ? apiBaseURL : kDefaultAPIBaseURL) copy];
        _serviceAccountKeyPath = [serviceAccountKeyPath copy];
        _transport = [transport retain];
    }
    return self;
}

- (void)dealloc {
    [_bucket release];
    [_apiBaseURL release];
    [_serviceAccountKeyPath release];
    [_transport release];
    [super dealloc];
}

- (NSInteger)statusCodeForResponse:(NSURLResponse *)response {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        return [(NSHTTPURLResponse *)response statusCode];
    }
    return -1;
}

- (NSError *)errorForStatus:(NSInteger)status body:(NSData *)body message:(NSString *)message {
    NSString *bodyString = body ? [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease] : @"";
    NSString *description = message ?: [NSString stringWithFormat:@"GCS request failed with status %ld: %@", (long)status, bodyString];
    return [NSError errorWithDomain:kErrorDomain
                                code:status
                            userInfo:@{ NSLocalizedDescriptionKey: description }];
}

// Resolves a bearer token from the configured service-account key. Returns
// [OTWBearerToken emptyToken] when no key is configured - the unauthenticated,
// emulator-compatible mode, which is a SUCCESSFUL resolution - or nil (with
// *error set) only when resolution actually fails. Callers only need to check
// whether the return value is nil to know whether an error occurred.
- (OTWBearerToken *)accessTokenWithError:(NSError **)error {
    if (_serviceAccountKeyPath == nil || [_serviceAccountKeyPath length] == 0) {
        return [OTWBearerToken emptyToken];
    }

    NSError *readError = nil;
    NSData *keyData = [NSData dataWithContentsOfFile:_serviceAccountKeyPath options:0 error:&readError];
    if (keyData == nil) {
        if (error) *error = readError ?: [self errorForStatus:-1 body:nil message:@"Could not read GCS service account key file"];
        return nil;
    }

    NSDictionary *keyJSON = [NSJSONSerialization JSONObjectWithData:keyData options:0 error:NULL];
    NSString *clientEmail = [keyJSON objectForKey:@"client_email"];
    NSString *privateKeyPEM = [keyJSON objectForKey:@"private_key"];
    NSString *tokenURI = [keyJSON objectForKey:@"token_uri"];
    if (tokenURI.length == 0) {
        tokenURI = kDefaultTokenURI;
    }
    if (clientEmail == nil || privateKeyPEM == nil) {
        if (error) *error = [self errorForStatus:-1 body:nil message:@"GCS service account key file missing client_email/private_key"];
        return nil;
    }

    NSString *assertion = PSMSignedJWTAssertion(clientEmail, tokenURI, kStorageScope, privateKeyPEM);
    if (assertion == nil) {
        if (error) *error = [self errorForStatus:-1 body:nil message:@"Failed to sign JWT assertion for GCS auth"];
        return nil;
    }

    NSString *bodyString = [NSString stringWithFormat:
        @"grant_type=urn%%3Aietf%%3Aparams%%3Aoauth%%3Agrant-type%%3Ajwt-bearer&assertion=%@", assertion];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:tokenURI]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];

    NSURLResponse *response = nil;
    NSError *transportError = nil;
    NSData *data = [_transport sendRequest:request response:&response error:&transportError];
    if (transportError) {
        if (error) *error = transportError;
        return nil;
    }
    NSInteger status = [self statusCodeForResponse:response];
    if (status < 200 || status >= 300) {
        if (error) *error = [self errorForStatus:status body:data message:nil];
        return nil;
    }
    NSDictionary *tokenJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    NSString *accessToken = [tokenJSON objectForKey:@"access_token"];
    if (accessToken == nil) {
        if (error) *error = [self errorForStatus:-1 body:data message:@"GCS token response missing access_token"];
        return nil;
    }
    return [OTWBearerToken tokenWithValue:accessToken];
}

- (void)applyAuthorization:(OTWBearerToken *)token toRequest:(NSMutableURLRequest *)request {
    if (![token isEmpty]) {
        [request setValue:[NSString stringWithFormat:@"Bearer %@", [token value]] forHTTPHeaderField:@"Authorization"];
    }
}

- (NSData *)downloadObjectAtPath:(NSString *)path
                            token:(OTWBearerToken *)token
                            error:(NSError **)error {
    NSString *urlString = [NSString stringWithFormat:@"%@/download/storage/v1/b/%@/o/%@?alt=media",
                            _apiBaseURL, _bucket, PSMURLEncodeObjectName(path)];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"GET"];
    [self applyAuthorization:token toRequest:request];

    NSURLResponse *response = nil;
    NSError *transportError = nil;
    NSData *data = [_transport sendRequest:request response:&response error:&transportError];
    if (transportError) {
        if (error) *error = transportError;
        return nil;
    }
    NSInteger status = [self statusCodeForResponse:response];
    if (status < 200 || status >= 300) {
        if (error) *error = [self errorForStatus:status body:data message:nil];
        return nil;
    }
    return data;
}

- (BOOL)uploadData:(NSData *)data
             toPath:(NSString *)path
              token:(OTWBearerToken *)token
              error:(NSError **)error {
    NSString *urlString = [NSString stringWithFormat:@"%@/upload/storage/v1/b/%@/o?uploadType=media&name=%@",
                            _apiBaseURL, _bucket, PSMURLEncodeObjectName(path)];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:data];
    [self applyAuthorization:token toRequest:request];

    NSURLResponse *response = nil;
    NSError *transportError = nil;
    NSData *respData = [_transport sendRequest:request response:&response error:&transportError];
    if (transportError) {
        if (error) *error = transportError;
        return NO;
    }
    NSInteger status = [self statusCodeForResponse:response];
    if (status < 200 || status >= 300) {
        if (error) *error = [self errorForStatus:status body:respData message:nil];
        return NO;
    }
    return YES;
}

- (BOOL)copyObjectFromPath:(NSString *)sourcePath
                      toPath:(NSString *)destinationPath
                       error:(NSError **)error {
    NSError *tokenError = nil;
    OTWBearerToken *token = [self accessTokenWithError:&tokenError];
    if (token == nil) {
        if (error) *error = tokenError;
        return NO;
    }

    NSError *downloadError = nil;
    NSData *data = [self downloadObjectAtPath:sourcePath token:token error:&downloadError];
    if (downloadError) {
        if (error) *error = downloadError;
        return NO;
    }

    NSError *uploadError = nil;
    BOOL uploaded = [self uploadData:data toPath:destinationPath token:token error:&uploadError];
    if (!uploaded) {
        if (error) *error = uploadError;
        return NO;
    }

    return YES;
}

- (BOOL)deleteObjectAtPath:(NSString *)path
                       error:(NSError **)error {
    NSError *tokenError = nil;
    OTWBearerToken *token = [self accessTokenWithError:&tokenError];
    if (token == nil) {
        if (error) *error = tokenError;
        return NO;
    }

    NSString *urlString = [NSString stringWithFormat:@"%@/storage/v1/b/%@/o/%@",
                            _apiBaseURL, _bucket, PSMURLEncodeObjectName(path)];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"DELETE"];
    [self applyAuthorization:token toRequest:request];

    NSURLResponse *response = nil;
    NSError *transportError = nil;
    NSData *data = [_transport sendRequest:request response:&response error:&transportError];
    if (transportError) {
        if (error) *error = transportError;
        return NO;
    }
    NSInteger status = [self statusCodeForResponse:response];
    if (status < 200 || status >= 300) {
        if (error) *error = [self errorForStatus:status body:data message:nil];
        return NO;
    }
    return YES;
}

@end
