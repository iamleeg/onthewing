// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestObservationMap.m - Tests for ObservationMap logic.
// Copyright (C) 2026 Graham Lee
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

#import "ObservationMap.h"
#import "ObservationLocation.h"
#import <XCTest/XCTest.h>

@interface TestObservationMap : XCTestCase
@end

@implementation TestObservationMap

- (WOContext *)dummyContext {
    WORequest *req = [[WORequest alloc] initWithMethod:@"GET"
                                               uri:@"/"
                                           httpVersion:@"HTTP/1.1"
                                               headers:nil
                                               content:nil
                                              userInfo:nil];
    return [[WOContext alloc] initWithRequest:req];
}

- (void)testHasValidCoordinatesBothPresent {
    WOContext *ctx = [self dummyContext];
    ObservationMap *map = [[ObservationMap alloc] initWithContext:ctx];
    ObservationLocation *loc = [[ObservationLocation alloc] init];
    [loc setLatitude:[NSNumber numberWithDouble:51.5074]];
    [loc setLongitude:[NSNumber numberWithDouble:-0.1278]];
    
    [map setLocation:loc];
    XCTAssertTrue([map hasValidCoordinates]);
    
    XCTAssertEqualObjects([map latitude], @"51.5074");
    XCTAssertEqualObjects([map longitude], @"-0.1278");
    
    [loc release];
    [map release];
    [ctx release];
}

- (void)testHasValidCoordinatesLatitudeOnly {
    WOContext *ctx = [self dummyContext];
    ObservationMap *map = [[ObservationMap alloc] initWithContext:ctx];
    ObservationLocation *loc = [[ObservationLocation alloc] init];
    [loc setLatitude:[NSNumber numberWithDouble:51.5074]];
    
    [map setLocation:loc];
    XCTAssertFalse([map hasValidCoordinates]);
    
    [loc release];
    [map release];
    [ctx release];
}

- (void)testHasValidCoordinatesLongitudeOnly {
    WOContext *ctx = [self dummyContext];
    ObservationMap *map = [[ObservationMap alloc] initWithContext:ctx];
    ObservationLocation *loc = [[ObservationLocation alloc] init];
    [loc setLongitude:[NSNumber numberWithDouble:-0.1278]];
    
    [map setLocation:loc];
    XCTAssertFalse([map hasValidCoordinates]);
    
    [loc release];
    [map release];
    [ctx release];
}

- (void)testHasValidCoordinatesNeitherPresent {
    WOContext *ctx = [self dummyContext];
    ObservationMap *map = [[ObservationMap alloc] initWithContext:ctx];
    ObservationLocation *loc = [[ObservationLocation alloc] init];
    
    [map setLocation:loc];
    XCTAssertFalse([map hasValidCoordinates]);
    
    [loc release];
    [map release];
    [ctx release];
}

- (void)testHasValidCoordinatesNoLocation {
    WOContext *ctx = [self dummyContext];
    ObservationMap *map = [[ObservationMap alloc] initWithContext:ctx];
    XCTAssertFalse([map hasValidCoordinates]);
    XCTAssertNil([map latitude]);
    XCTAssertNil([map longitude]);
    
    [map release];
    [ctx release];
}

@end
