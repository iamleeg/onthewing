// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestApp.m - Tests for the OTWApp class
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

#import "OTWApp.h"
#import <XCTest/XCTest.h>

@interface TestApp : XCTestCase
@end

@implementation TestApp

- (void)setUp {
  [super setUp];
}

- (void)testSessionTimeOut {
  NSNumber *timeout = [OTWApp sessionTimeOut];
  XCTAssertEqualObjects(timeout, @60);
}

- (void)testInitSetsDefaultRequestHandler {
  OTWApp *app = [[OTWApp alloc] init];
  NSString *directActionHandlerKey =
      [[app class] directActionRequestHandlerKey];
  WORequestHandler *handler = [app requestHandlerForKey:directActionHandlerKey];
  XCTAssertEqualObjects([app defaultRequestHandler], handler);
}

- (void)testInitSetsMessageEncoding {
  OTWApp *app = [[OTWApp alloc] init];
  (void)app; // just to silence unused variable if needed
  XCTAssertEqual([WOMessage defaultEncoding],
                 (NSStringEncoding)NSUTF8StringEncoding);
}

@end
