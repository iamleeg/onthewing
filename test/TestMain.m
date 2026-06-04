// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestMain.m - Tests for the Main class
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

#import "Capture.h"
#import "Main.h"
#import "OTWApp.h"
#import <XCTest/XCTest.h>

@interface TestMain : XCTestCase
@end

@implementation TestMain

- (void)testMainInstantiation {
  OTWApp *app = [[OTWApp alloc] init];
  WORequest *req = [[WORequest alloc] initWithMethod:@"GET"
                                                 uri:@"/"
                                         httpVersion:@"HTTP/1.1"
                                             headers:nil
                                             content:nil
                                            userInfo:nil];
  WOContext *ctx = [[WOContext alloc] initWithRequest:req];
  Main *m = [[Main alloc] initWithContext:ctx];
  XCTAssertNotNil(m);
}

- (void)testMainReturnsCapturePage {
  OTWApp *app = [[OTWApp alloc] init];
  WORequest *req = [[WORequest alloc] initWithMethod:@"GET"
                                                 uri:@"/"
                                         httpVersion:@"HTTP/1.1"
                                             headers:nil
                                             content:nil
                                            userInfo:nil];
  WOContext *ctx = [[WOContext alloc] initWithRequest:req];
  Main *m = [[Main alloc] initWithContext:ctx];
  Capture *capture = [m capture];
  XCTAssertEqualObjects([capture class], [Capture class]);
  XCTAssertNotNil([[capture observation] captureDate]);
}

@end
