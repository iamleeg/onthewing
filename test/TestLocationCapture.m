// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestLocationCapture.m - Tests for the LocationCapture component.
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

#import "LocationCapture.h"
#import "ObservationLocation.h"
#import "Session.h"
#import "Capture.h"
#import "TestOTWApp.h"
#import <XCTest/XCTest.h>

@interface TestLocationCapture : XCTestCase
{
  OTWApp *_app;
  WORequest *_req;
  WOContext *_ctx;
  LocationCapture *_lc;
  Session *_session;
}
@end

@implementation TestLocationCapture

- (void)setUp {
  _app = [[TestOTWApp alloc] init];
  _req = [[WORequest alloc] initWithMethod:@"GET"
                                       uri:@"/"
                               httpVersion:@"HTTP/1.1"
                                   headers:nil
                                   content:nil
                                  userInfo:nil];
  _ctx = [[WOContext alloc] initWithRequest:_req];
  _lc = [[LocationCapture alloc] initWithContext:_ctx];
  _session = (Session *)[_lc session];
}

- (void)tearDown {
  [_lc release]; _lc = nil;
  [_ctx release]; _ctx = nil;
  [_req release]; _req = nil;
  [_app release]; _app = nil;
}

- (void)testRecordLocationAndBearingPermissionDenied {
  [_session setLocationPermissionState:LocationPermissionUndetermined];
  [_lc setLocationError:@"1"];
  [_lc setNextComponent:@"Capture"];
  
  id next = [_lc recordLocationAndBearing];
  
  XCTAssertEqual([_session locationPermissionState], LocationPermissionDenied);
  XCTAssertEqualObjects([next class], [Capture class]);
  XCTAssertEqualObjects([(Capture *)next locationError], @"No location data was captured.");
}

- (void)testRecordLocationAndBearingPermissionAllowedAndCaptured {
  [_lc setObservation: [[[Observation alloc] init] autorelease]];

  [_session setLocationPermissionState:LocationPermissionUndetermined];
  [_lc setLatitude:@"51.5074"];
  [_lc setLongitude:@"-0.1278"];
  [_lc setAccuracy:@"10.0"];
  [_lc setBearing:@"180.0"];
  [_lc setNextComponent:@"Capture"];
  
  id next = [_lc recordLocationAndBearing];
  
  XCTAssertEqual([_session locationPermissionState], LocationPermissionAllowed);
  XCTAssertEqualObjects([next class], [Capture class]);
  
  Capture *capturePage = (Capture *)next;
  ObservationLocation *loc = [[capturePage observation] location];
  
  XCTAssertNotNil(loc);
  XCTAssertEqualWithAccuracy([[loc latitude] doubleValue], 51.5074, 0.0001);
  XCTAssertEqualWithAccuracy([[loc longitude] doubleValue], -0.1278, 0.0001);
  XCTAssertEqualWithAccuracy([[loc accuracy] doubleValue], 10.0, 0.0001);
  XCTAssertEqualWithAccuracy([[loc bearing] doubleValue], 180.0, 0.0001);
}

- (void)testRecordLocationAndBearingEmptyBearing {
  [_lc setObservation: [[[Observation alloc] init] autorelease]];
  [_lc setLatitude:@"51.5074"];
  [_lc setLongitude:@"-0.1278"];
  [_lc setBearing:@""];
  [_lc setNextComponent:@"Capture"];
  
  id next = [_lc recordLocationAndBearing];
  Capture *capturePage = (Capture *)next;
  ObservationLocation *loc = [[capturePage observation] location];
  
  XCTAssertNotNil(loc);
  XCTAssertNil([loc bearing], @"Bearing should be nil when provided as an empty string");
}

@end
