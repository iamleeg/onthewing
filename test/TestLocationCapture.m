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
#import "OTWApp.h"
#import <XCTest/XCTest.h>

@interface TestLocationCapture : XCTestCase
@end

@implementation TestLocationCapture

- (void)testLocationCaptureInstantiation {
  OTWApp *app = [[OTWApp alloc] init];
  WORequest *req = [[WORequest alloc] initWithMethod:@"GET"
                                                 uri:@"/"
                                         httpVersion:@"HTTP/1.1"
                                             headers:nil
                                             content:nil
                                            userInfo:nil];
  WOContext *ctx = [[WOContext alloc] initWithRequest:req];
  LocationCapture *lc = [[LocationCapture alloc] initWithContext:ctx];
  
  XCTAssertNotNil(lc);
  XCTAssertNil([lc latitude]);
  XCTAssertNil([lc longitude]);
  XCTAssertNil([lc accuracy]);
  XCTAssertNil([lc bearing]);
  XCTAssertNil([lc locationError]);
  XCTAssertNil([lc bearingError]);
  XCTAssertNil([lc nextComponent]);
  // deviceCaptureScriptTag always returns a non-nil string (falls back to a comment if
  // there is no resource manager, which is expected in a test-harness context).
  XCTAssertNotNil([lc deviceCaptureScriptTag]);

  [lc release];
}

- (void)testRecordLocationAndBearingPermissionDenied {
  OTWApp *app = [[OTWApp alloc] init];
  WORequest *req = [[WORequest alloc] initWithMethod:@"POST"
                                                 uri:@"/"
                                         httpVersion:@"HTTP/1.1"
                                             headers:nil
                                             content:nil
                                            userInfo:nil];
  WOContext *ctx = [[WOContext alloc] initWithRequest:req];
  LocationCapture *lc = [[LocationCapture alloc] initWithContext:ctx];
  Session *session = (Session *)[lc session];
  
  [session setLocationPermissionState:LocationPermissionUndetermined];
  [lc setLocationError:@"1"];
  [lc setNextComponent:@"Capture"];
  
  id next = [lc recordLocationAndBearing];
  
  XCTAssertEqual([session locationPermissionState], LocationPermissionDenied);
  XCTAssertEqualObjects([next class], [Capture class]);
  XCTAssertEqualObjects([(Capture *)next locationError], @"No location data was captured.");
  
  [lc release];
}

- (void)testRecordLocationAndBearingPermissionAllowedAndCaptured {
  OTWApp *app = [[OTWApp alloc] init];
  WORequest *req = [[WORequest alloc] initWithMethod:@"POST"
                                                 uri:@"/"
                                         httpVersion:@"HTTP/1.1"
                                             headers:nil
                                             content:nil
                                            userInfo:nil];
  WOContext *ctx = [[WOContext alloc] initWithRequest:req];
  LocationCapture *lc = [[LocationCapture alloc] initWithContext:ctx];
  Session *session = (Session *)[lc session];
  
  [session setLocationPermissionState:LocationPermissionUndetermined];
  [lc setLatitude:@"51.5074"];
  [lc setLongitude:@"-0.1278"];
  [lc setAccuracy:@"10.0"];
  [lc setBearing:@"180.0"];
  [lc setNextComponent:@"Capture"];
  
  id next = [lc recordLocationAndBearing];
  
  XCTAssertEqual([session locationPermissionState], LocationPermissionAllowed);
  XCTAssertEqualObjects([next class], [Capture class]);
  
  Capture *capturePage = (Capture *)next;
  ObservationLocation *loc = [capturePage capturedLocation];
  
  XCTAssertNotNil(loc);
  XCTAssertEqualWithAccuracy([[loc latitude] doubleValue], 51.5074, 0.0001);
  XCTAssertEqualWithAccuracy([[loc longitude] doubleValue], -0.1278, 0.0001);
  XCTAssertEqualWithAccuracy([[loc accuracy] doubleValue], 10.0, 0.0001);
  XCTAssertEqualWithAccuracy([[loc bearing] doubleValue], 180.0, 0.0001);
  
  [lc release];
}

@end
