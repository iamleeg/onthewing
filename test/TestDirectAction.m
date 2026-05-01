// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestDirectAction.m - Tests for the DirectAction class
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

#import "DirectAction.h"
#import "OTWApp.h"
#import "Main.h"
#import <XCTest/XCTest.h>

@interface TestDirectAction : XCTestCase
@end

@implementation TestDirectAction

- (void)testDefaultActionReturnsMainPage {
  OTWApp *app = [[OTWApp alloc] init];
  (void)app;
  WORequest *req = [[WORequest alloc] initWithMethod:@"GET"
                                                  uri:@"/"
                                          httpVersion:@"HTTP/1.1"
                                              headers:nil
                                              content:nil
                                             userInfo:nil];
  DirectAction *da = [[DirectAction alloc] initWithRequest:req];
  id results = [da defaultAction];
  XCTAssertTrue([results isKindOfClass:[Main class]]);
}

@end
