// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestObservationLocation.m - Tests for the ObservationLocation DTO.
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

#import "ObservationLocation.h"
#import <XCTest/XCTest.h>

@interface TestObservationLocation : XCTestCase
@end

@implementation TestObservationLocation

- (void)testObservationLocationInstantiation {
  ObservationLocation *loc = [[ObservationLocation alloc] init];
  XCTAssertNotNil(loc);
  XCTAssertNil([loc latitude]);
  XCTAssertNil([loc longitude]);
  XCTAssertNil([loc accuracy]);
  XCTAssertNil([loc bearing]);
  [loc release];
}

- (void)testObservationLocationPropertySetting {
  ObservationLocation *loc = [[ObservationLocation alloc] init];
  
  NSNumber *lat = [NSNumber numberWithDouble:51.5074];
  NSNumber *lon = [NSNumber numberWithDouble:-0.1278];
  NSNumber *acc = [NSNumber numberWithDouble:10.0];
  NSNumber *bear = [NSNumber numberWithDouble:180.0];
  
  [loc setLatitude:lat];
  [loc setLongitude:lon];
  [loc setAccuracy:acc];
  [loc setBearing:bear];
  
  XCTAssertEqualObjects([loc latitude], lat);
  XCTAssertEqualObjects([loc longitude], lon);
  XCTAssertEqualObjects([loc accuracy], acc);
  XCTAssertEqualObjects([loc bearing], bear);
  
  [loc release];
}

@end
