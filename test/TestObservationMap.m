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
{
    WOContext *_ctx;
    ObservationMap *_map;
}
@end

@implementation TestObservationMap

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
    _map = [[ObservationMap alloc] initWithContext:_ctx];
}

- (void)tearDown {
    [_ctx release]; _ctx = nil;
    [_map release]; _map = nil;
}

- (void)testHasValidCoordinatesBothPresent {
    ObservationLocation *loc = [[ObservationLocation alloc] init];
    [loc setLatitude:[NSNumber numberWithDouble:51.5074]];
    [loc setLongitude:[NSNumber numberWithDouble:-0.1278]];
    
    [_map setLocation:loc];
    XCTAssertTrue([_map hasValidCoordinates]);
    
    XCTAssertEqualObjects([_map latitude], @"51.5074");
    XCTAssertEqualObjects([_map longitude], @"-0.1278");
    
    [loc release];
}

- (void)testHasValidCoordinatesLatitudeOnly {
    ObservationLocation *loc = [[ObservationLocation alloc] init];
    [loc setLatitude:[NSNumber numberWithDouble:51.5074]];
    
    [_map setLocation:loc];
    XCTAssertFalse([_map hasValidCoordinates]);
    
    [loc release];
}

- (void)testHasValidCoordinatesLongitudeOnly {
    ObservationLocation *loc = [[ObservationLocation alloc] init];
    [loc setLongitude:[NSNumber numberWithDouble:-0.1278]];
    
    [_map setLocation:loc];
    XCTAssertFalse([_map hasValidCoordinates]);
    
    [loc release];
}

- (void)testHasValidCoordinatesNeitherPresent {
    ObservationLocation *loc = [[ObservationLocation alloc] init];
    
    [_map setLocation:loc];
    XCTAssertFalse([_map hasValidCoordinates]);
    
    [loc release];
}

- (void)testHasValidCoordinatesNoLocation {
    XCTAssertFalse([_map hasValidCoordinates]);
    XCTAssertNil([_map latitude]);
    XCTAssertNil([_map longitude]);
}

@end
