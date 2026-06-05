// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestCapture.m - Tests for the Capture component.
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
//

#import "Capture.h"
#import "Main.h"
#import "Observation.h"
#import "ObservationLocation.h"
#import "Session.h"
#import <XCTest/XCTest.h>

@interface TestCapture : XCTestCase
@end

@implementation TestCapture

- (WOContext *)dummyContext {
  WORequest *req = [[WORequest alloc] initWithMethod:@"GET"
                                               uri:@"/"
                                           httpVersion:@"HTTP/1.1"
                                               headers:nil
                                               content:nil
                                              userInfo:nil];
  return [[[WOContext alloc] initWithRequest:req] autorelease];
}

- (void)testCaptureInstantiation {
  WOContext *ctx = [self dummyContext];
  Capture *capture = [[Capture alloc] initWithContext:ctx];
  XCTAssertNotNil(capture);
  XCTAssertNil([capture observation]);
  XCTAssertNil([capture locationError]);
  [capture release];
}

- (void)testSetLocationError {
  WOContext *ctx = [self dummyContext];
  Capture *capture = [[Capture alloc] initWithContext:ctx];
  NSString *error = @"Invalid location";
  
  [capture setLocationError:error];
  XCTAssertEqualObjects([capture locationError], error);
  
  [capture release];
}

- (void)testReturnAddsPendingObservation {
  WOContext *ctx = [self dummyContext];
  Session *s = [ctx session];
  Observation *o = [Observation new];
  Capture *capture = [[Capture alloc] initWithContext:ctx];
  [capture setObservation: o];

  id page = [capture return];
  XCTAssertEqualObjects([page class], [Main class]);
  XCTAssertTrue([[s unreviewedObservations] containsObject:o]);

  [capture release];
  [o release];
}
@end
