// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestPhotoStorageMover.m - Tests for the PhotoStorageMover class
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
#import <XCTest/XCTest.h>

// Records every request it receives and returns pre-planned responses in
// order, without any real networking.
@interface FakeTransport : NSObject <PhotoStorageMoverTransport>
{
    NSMutableArray *_recordedRequests;
    NSMutableArray *_plannedResponses;
    NSUInteger _callIndex;
}
@property (nonatomic, readonly) NSMutableArray *recordedRequests;
- (void)addResponseWithStatus:(NSInteger)status data:(NSData *)data;
- (void)addErrorResponse:(NSError *)error;
@end

@implementation FakeTransport

@synthesize recordedRequests = _recordedRequests;

- (id)init {
    self = [super init];
    if (self) {
        _recordedRequests = [[NSMutableArray alloc] init];
        _plannedResponses = [[NSMutableArray alloc] init];
        _callIndex = 0;
    }
    return self;
}

- (void)dealloc {
    [_recordedRequests release];
    [_plannedResponses release];
    [super dealloc];
}

- (void)addResponseWithStatus:(NSInteger)status data:(NSData *)data {
    [_plannedResponses addObject:@{ @"status": @(status), @"data": (data ?: [NSData data]) }];
}

- (void)addErrorResponse:(NSError *)error {
    [_plannedResponses addObject:@{ @"error": error }];
}

- (NSData *)sendRequest:(NSURLRequest *)request
                response:(NSURLResponse **)response
                   error:(NSError **)error {
    [_recordedRequests addObject:request];
    if (_callIndex >= [_plannedResponses count]) {
        XCTFail(@"FakeTransport received more requests than planned responses");
        return nil;
    }
    NSDictionary *planned = [_plannedResponses objectAtIndex:_callIndex];
    _callIndex++;

    NSError *plannedError = [planned objectForKey:@"error"];
    if (plannedError) {
        if (error) *error = plannedError;
        return nil;
    }
    NSInteger status = [[planned objectForKey:@"status"] integerValue];
    if (response) {
        *response = [[[NSHTTPURLResponse alloc] initWithURL:[request URL]
                                                    statusCode:status
                                                   HTTPVersion:@"HTTP/1.1"
                                                  headerFields:nil] autorelease];
    }
    return [planned objectForKey:@"data"];
}

@end

@interface TestPhotoStorageMover : XCTestCase
@end

@implementation TestPhotoStorageMover

- (void)testCopySucceedsAndDoesNotTouchSource {
    FakeTransport *transport = [[[FakeTransport alloc] init] autorelease];
    NSData *photoBytes = [@"fake-photo-bytes" dataUsingEncoding:NSUTF8StringEncoding];
    [transport addResponseWithStatus:200 data:photoBytes];
    [transport addResponseWithStatus:200 data:[NSData data]];

    PhotoStorageMover *mover = [[PhotoStorageMover alloc] initWithBucket:@"test-bucket"
                                                                apiBaseURL:@"http://emulator.local:9199"
                                                     serviceAccountKeyPath:nil
                                                                 transport:transport];

    NSError *error = nil;
    BOOL success = [mover copyObjectFromPath:@"temp/uid/photo.jpg"
                                        toPath:@"journal/uid/entry1/photo.jpg"
                                         error:&error];

    XCTAssertTrue(success);
    XCTAssertNil(error);
    XCTAssertEqual([[transport recordedRequests] count], (NSUInteger)2);

    NSURLRequest *getRequest = [[transport recordedRequests] objectAtIndex:0];
    XCTAssertEqualObjects([getRequest HTTPMethod], @"GET");
    XCTAssertTrue([[[getRequest URL] absoluteString] containsString:@"temp%2Fuid%2Fphoto.jpg"]);
    XCTAssertNil([getRequest valueForHTTPHeaderField:@"Authorization"]);

    NSURLRequest *postRequest = [[transport recordedRequests] objectAtIndex:1];
    XCTAssertEqualObjects([postRequest HTTPMethod], @"POST");
    XCTAssertTrue([[[postRequest URL] absoluteString] containsString:@"journal%2Fuid%2Fentry1%2Fphoto.jpg"]);

    for (NSURLRequest *req in [transport recordedRequests]) {
        XCTAssertFalse([[req HTTPMethod] isEqualToString:@"DELETE"]);
    }

    [mover release];
}

- (void)testCopyFailsWhenDownloadFails {
    FakeTransport *transport = [[[FakeTransport alloc] init] autorelease];
    [transport addResponseWithStatus:404 data:nil];

    PhotoStorageMover *mover = [[PhotoStorageMover alloc] initWithBucket:@"test-bucket"
                                                                apiBaseURL:@"http://emulator.local:9199"
                                                     serviceAccountKeyPath:nil
                                                                 transport:transport];

    NSError *error = nil;
    BOOL success = [mover copyObjectFromPath:@"temp/uid/photo.jpg"
                                        toPath:@"journal/uid/entry1/photo.jpg"
                                         error:&error];

    XCTAssertFalse(success);
    XCTAssertNotNil(error);
    [mover release];
}

- (void)testCopyFailsWhenUploadFailsAndSourceIsUntouched {
    FakeTransport *transport = [[[FakeTransport alloc] init] autorelease];
    NSData *photoBytes = [@"fake-photo-bytes" dataUsingEncoding:NSUTF8StringEncoding];
    [transport addResponseWithStatus:200 data:photoBytes];
    [transport addResponseWithStatus:500 data:nil];

    PhotoStorageMover *mover = [[PhotoStorageMover alloc] initWithBucket:@"test-bucket"
                                                                apiBaseURL:@"http://emulator.local:9199"
                                                     serviceAccountKeyPath:nil
                                                                 transport:transport];

    NSError *error = nil;
    BOOL success = [mover copyObjectFromPath:@"temp/uid/photo.jpg"
                                        toPath:@"journal/uid/entry1/photo.jpg"
                                         error:&error];

    XCTAssertFalse(success);
    XCTAssertNotNil(error);
    for (NSURLRequest *req in [transport recordedRequests]) {
        XCTAssertFalse([[req HTTPMethod] isEqualToString:@"DELETE"]);
    }
    [mover release];
}

- (void)testDeleteSucceeds {
    FakeTransport *transport = [[[FakeTransport alloc] init] autorelease];
    [transport addResponseWithStatus:204 data:nil];

    PhotoStorageMover *mover = [[PhotoStorageMover alloc] initWithBucket:@"test-bucket"
                                                                apiBaseURL:@"http://emulator.local:9199"
                                                     serviceAccountKeyPath:nil
                                                                 transport:transport];

    NSError *error = nil;
    BOOL success = [mover deleteObjectAtPath:@"temp/uid/photo.jpg" error:&error];

    XCTAssertTrue(success);
    XCTAssertNil(error);
    XCTAssertEqual([[transport recordedRequests] count], (NSUInteger)1);
    NSURLRequest *req = [[transport recordedRequests] objectAtIndex:0];
    XCTAssertEqualObjects([req HTTPMethod], @"DELETE");
    XCTAssertTrue([[[req URL] absoluteString] containsString:@"temp%2Fuid%2Fphoto.jpg"]);
    [mover release];
}

- (void)testDeleteFails {
    FakeTransport *transport = [[[FakeTransport alloc] init] autorelease];
    [transport addResponseWithStatus:403 data:nil];

    PhotoStorageMover *mover = [[PhotoStorageMover alloc] initWithBucket:@"test-bucket"
                                                                apiBaseURL:@"http://emulator.local:9199"
                                                     serviceAccountKeyPath:nil
                                                                 transport:transport];

    NSError *error = nil;
    BOOL success = [mover deleteObjectAtPath:@"temp/uid/photo.jpg" error:&error];

    XCTAssertFalse(success);
    XCTAssertNotNil(error);
    [mover release];
}

// Exercises the real service-account-key-reading + JWT-signing + OAuth2
// token-exchange path (every other test injects serviceAccountKeyPath:nil,
// which skips this entirely - that gap let a broken
// +[NSData dataWithContentsOfFile:options:error:] call reach production
// undetected, since that selector doesn't exist in the GNUstep-base version
// this app actually ships against and throws instead of returning
// nil-plus-error; -accessTokenWithError: now uses the older, available
// +dataWithContentsOfFile: instead).
- (void)testDeleteSucceedsWithRealServiceAccountKeyFile {
    NSString *testRSAPrivateKeyPEM =
        @"-----BEGIN PRIVATE KEY-----\n"
        @"MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCpH4vy/FYznkBP\n"
        @"TXqp1BApUjXd8mmCKKzs7558LRVgRDslXxDvr7bzj3PoTAWmcSrNMHWkbZ8y1Yk2\n"
        @"j+w9mRXEj2wJpq0DfoMmIwYljySCS+e5IbL26C+mPVEbGyqnuO+7aH1uyGSlwQ1y\n"
        @"2GJkK3sAjyZhI7pU7xeZJ7JdFqlrRett4pGKW0ISuBdJLMgwX2v6wJ3BuMG4XDur\n"
        @"C+HO3YQkmpcOJ8R/AMuk1ziBAMbrhqoiyq2buSYaP6k1A1CC/OfCj5ewAu1dFRnH\n"
        @"JRt4s9EbeIVvTLXKFbYEKJQtdH5OPpg1pTofKqm0ZRNwdpMzxUtzvipTZDFqXF8F\n"
        @"WIeZUGJvAgMBAAECggEAP0+BbuFajbE4ptc8y5WIxUcyxhbIu4Jplbrv69Fetq5k\n"
        @"K83GQ8vWI6A4hiXrWY70tGJnL7ofxgJc/tFq4PZNSUtdaNF95Bh4lQ64btgClUpA\n"
        @"ATRlz/tEVymOEqUdVzMqf1AS4KVg1BIMbEknsBL81U1BU0zyJHhqr5lGMoXYv0CN\n"
        @"jhEY9RNCLWIEyuepSec2CZw8mDNFhrKOcZX1sDBlObmAvmI+naKErcUO+abP9dsQ\n"
        @"Bh3qquKF6KOBqfgi07YB4jUMOoEZBMEb4cin7ketPSukG/XC9NnO25rbMhTD+Xjz\n"
        @"yGTphb90VzhgrjUENuYjTmUYbs+rJELcPnMlV/Ck8QKBgQDi5DFCOeuOqjnJmIUM\n"
        @"ivop9Q59Frzgccwrciik79N9e4QS3jgADK0wHEZaJBttXSGXLDr0uBdFHPUOHkrU\n"
        @"KhxU3oUUDytLcSdYKlmKuIJxhVZofcSAPRWqkM97NcgLC9hT0WtlVNJ9hmHu4ZNn\n"
        @"aZ7lAW4w79qHi5yhKIfS+PAwMQKBgQC+0hJHgzBCpjJuTKDoG5LpDslrxGYnuH+d\n"
        @"5eVrxhLAFYXplnaFcBZCNEA+BAPmyHgOWrWM4K1lThqbsw462Z9YbZZBqirkDZmo\n"
        @"BGqr8xJHGl5O2LA40iXzrQ4S89gxJH6OdsLZrBQrK8Q7o4vKpgl5F9Ar739aw+qG\n"
        @"H0/FbkC0nwKBgBcz2s24+pvWUJ6LGGAV/ks4IkksgBg7yvNOc1WaqPgWH4WGcBeh\n"
        @"NDzNR2yEcMGYWo0JGuZXxRluQqk089YKkGclclqAyp6mba2Ydxu2jrBpQFLjOasb\n"
        @"lBGjSXSCJXjrty2rJt5v9C6eBXnWW6qhpHwqz0f131UpM9VPPcSXbIihAoGBAI/C\n"
        @"eB8ESPGNgGT0uizjyTRn/XuBRW0bZJmyv7sISMwJ6w9mWfiBz2MlNlkCcWYHFdvK\n"
        @"nwh5pGi0BPvUVB4mIhRey1rBNvsE/ARG/4533AdRaEeCnJDSUeFZOUcyCmhLlEUE\n"
        @"WBvhtngnyvkbZ4/Os0hVlnHjR1E8VI2jPVgCjiEFAoGAYSBpET5Uaxzf1/yGxpFt\n"
        @"C2gr0uq1tv5e0CF7986y6RRbd9pqHazFMwOR71+qtf4F3cbhZr+vpp9WiLJDFkVx\n"
        @"Bf3+Bv8snhFoEC0NhfkwryedGA8xzWtb0v9OxiMsAMyCOogQIlspXAznkVw6bkTU\n"
        @"KwCaEnpKxWpD3zmsBLmKIn8=\n"
        @"-----END PRIVATE KEY-----\n";

    NSDictionary *serviceAccountJSON = @{
        @"client_email": @"test@test-project.iam.gserviceaccount.com",
        @"private_key": testRSAPrivateKeyPEM,
        @"token_uri": @"http://emulator.local:9199/token"
    };
    NSString *keyPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
                          [NSString stringWithFormat:@"test-service-account-%@.json", [[NSUUID UUID] UUIDString]]];
    NSData *keyFileData = [NSJSONSerialization dataWithJSONObject:serviceAccountJSON options:0 error:NULL];
    [keyFileData writeToFile:keyPath atomically:YES];

    FakeTransport *transport = [[[FakeTransport alloc] init] autorelease];
    NSDictionary *tokenResponseJSON = @{ @"access_token": @"fake-access-token-123" };
    [transport addResponseWithStatus:200 data:[NSJSONSerialization dataWithJSONObject:tokenResponseJSON options:0 error:NULL]];
    [transport addResponseWithStatus:204 data:nil];

    PhotoStorageMover *mover = [[PhotoStorageMover alloc] initWithBucket:@"test-bucket"
                                                                apiBaseURL:@"http://emulator.local:9199"
                                                     serviceAccountKeyPath:keyPath
                                                                 transport:transport];

    NSError *error = nil;
    BOOL success = [mover deleteObjectAtPath:@"temp/uid/photo.jpg" error:&error];

    XCTAssertTrue(success, @"delete failed with error: %@", error);
    XCTAssertNil(error);
    XCTAssertEqual([[transport recordedRequests] count], (NSUInteger)2);

    NSURLRequest *tokenRequest = [[transport recordedRequests] objectAtIndex:0];
    XCTAssertEqualObjects([tokenRequest HTTPMethod], @"POST");

    NSURLRequest *deleteRequest = [[transport recordedRequests] objectAtIndex:1];
    XCTAssertEqualObjects([deleteRequest HTTPMethod], @"DELETE");
    XCTAssertEqualObjects([deleteRequest valueForHTTPHeaderField:@"Authorization"], @"Bearer fake-access-token-123");

    [mover release];
    [[NSFileManager defaultManager] removeItemAtPath:keyPath error:NULL];
}

- (void)testNoAuthorizationHeaderWhenNoServiceAccountKeyConfigured {
    FakeTransport *transport = [[[FakeTransport alloc] init] autorelease];
    [transport addResponseWithStatus:204 data:nil];

    PhotoStorageMover *mover = [[PhotoStorageMover alloc] initWithBucket:@"test-bucket"
                                                                apiBaseURL:@"http://emulator.local:9199"
                                                     serviceAccountKeyPath:nil
                                                                 transport:transport];

    NSError *error = nil;
    [mover deleteObjectAtPath:@"temp/uid/photo.jpg" error:&error];

    XCTAssertEqual([[transport recordedRequests] count], (NSUInteger)1);
    XCTAssertNil([[[transport recordedRequests] objectAtIndex:0] valueForHTTPHeaderField:@"Authorization"]);
    [mover release];
}

@end
