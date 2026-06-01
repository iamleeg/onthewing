// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestCompassSVGGenerator.m - Tests for CompassSVGGenerator.
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
// along with this program.

#import "CompassSVGGenerator.h"
#import <XCTest/XCTest.h>

@interface TestCompassSVGGenerator : XCTestCase
@end

@implementation TestCompassSVGGenerator

- (void)testNilBearingReturnsEmptyString {
    CompassSVGGenerator *gen = [[CompassSVGGenerator alloc] init];
    NSString *svg = [gen svgForBearing:nil];
    XCTAssertEqualObjects(svg, @"");
    [gen release];
}

- (void)testNorthBearing {
    CompassSVGGenerator *gen = [[CompassSVGGenerator alloc] init];
    NSNumber *bearing = [NSNumber numberWithDouble:0.0];
    NSString *svg = [gen svgForBearing:bearing];
    XCTAssertTrue([svg containsString:@"transform=\"rotate(0.00, 50, 50)\""]);
    [gen release];
}

- (void)testEastBearing {
    CompassSVGGenerator *gen = [[CompassSVGGenerator alloc] init];
    NSNumber *bearing = [NSNumber numberWithDouble:90.0];
    NSString *svg = [gen svgForBearing:bearing];
    XCTAssertTrue([svg containsString:@"transform=\"rotate(90.00, 50, 50)\""]);
    [gen release];
}

- (void)testSouthBearing {
    CompassSVGGenerator *gen = [[CompassSVGGenerator alloc] init];
    NSNumber *bearing = [NSNumber numberWithDouble:180.0];
    NSString *svg = [gen svgForBearing:bearing];
    XCTAssertTrue([svg containsString:@"transform=\"rotate(180.00, 50, 50)\""]);
    [gen release];
}

- (void)testWestBearing {
    CompassSVGGenerator *gen = [[CompassSVGGenerator alloc] init];
    NSNumber *bearing = [NSNumber numberWithDouble:270.0];
    NSString *svg = [gen svgForBearing:bearing];
    XCTAssertTrue([svg containsString:@"transform=\"rotate(270.00, 50, 50)\""]);
    [gen release];
}

- (void)testSVGContainsArrowhead {
    CompassSVGGenerator *gen = [[CompassSVGGenerator alloc] init];
    NSNumber *bearing = [NSNumber numberWithDouble:45.0];
    NSString *svg = [gen svgForBearing:bearing];
    XCTAssertTrue([svg containsString:@"<polygon"]);
    [gen release];
}

@end
