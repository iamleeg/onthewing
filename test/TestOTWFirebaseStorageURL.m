// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestOTWFirebaseStorageURL.m - Tests for the OTWFirebaseStorageURL class
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

#import "OTWFirebaseStorageURL.h"
#import <XCTest/XCTest.h>

@interface TestOTWFirebaseStorageURL : XCTestCase
@end

@implementation TestOTWFirebaseStorageURL

- (void)testNilURLReturnsNil {
    XCTAssertNil([OTWFirebaseStorageURL objectPathFromDownloadURL:nil]);
}

- (void)testURLWithoutOComponentReturnsNil {
    NSURL *url = [NSURL URLWithString:@"https://example.com/some/other/path"];
    XCTAssertNil([OTWFirebaseStorageURL objectPathFromDownloadURL:url]);
}

- (void)testDecodesEncodedSlashesAndStripsQuery {
    NSURL *url = [NSURL URLWithString:@"https://firebasestorage.googleapis.com/v0/b/bucket/o/temp%2Fuid%2Fphoto.jpg?alt=media&token=abc"];
    XCTAssertEqualObjects([OTWFirebaseStorageURL objectPathFromDownloadURL:url], @"temp/uid/photo.jpg");
}

- (void)testWorksAgainstEmulatorHost {
    NSURL *url = [NSURL URLWithString:@"http://localhost:9199/v0/b/bucket/o/temp%2Fuid%2Fphoto.jpg?alt=media"];
    XCTAssertEqualObjects([OTWFirebaseStorageURL objectPathFromDownloadURL:url], @"temp/uid/photo.jpg");
}

@end
