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
{
  WOContext *_ctx;
  Capture *_capture;
}
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

- (void)setUp {
  _ctx = [[self dummyContext] retain];
  _capture = [[Capture alloc] initWithContext:_ctx];
}

- (void)tearDown {
  [_capture release]; _capture = nil;
  [_ctx release]; _ctx = nil;
}

- (void)testSetLocationError {
  NSString *error = @"Invalid location";
  
  [_capture setLocationError:error];
  XCTAssertEqualObjects([_capture locationError], error);
}

- (void)testPrepareFreshObservationSetsObservationWithCaptureDate {
  XCTAssertNil([_capture observation]);

  [_capture prepareFreshObservation];

  XCTAssertNotNil([_capture observation]);
  XCTAssertNotNil([[_capture observation] captureDate]);
}

- (void)testReturnAddsPendingObservation {
  Session *s = (Session *)[_ctx session];
  Observation *o = [Observation new];
  [_capture setObservation: o];

  id page = [_capture return];
  XCTAssertEqualObjects([page class], [Main class]);
  XCTAssertTrue([[s unreviewedObservations] containsObject:o]);

  [o release];
}

@end
