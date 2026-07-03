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
