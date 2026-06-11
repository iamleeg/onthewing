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
#import "Observation.h"
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

- (void)testSetLocationWrapsInObservationsAndMarkersJSON {
    ObservationLocation *loc = [[ObservationLocation alloc] init];
    [loc setLatitude:[NSNumber numberWithDouble:51.5074]];
    [loc setLongitude:[NSNumber numberWithDouble:-0.1278]];
    
    [_map setLocation:loc];
    XCTAssertNotNil([_map observations]);
    XCTAssertEqual([[_map observations] count], (NSUInteger)1);
    
    NSString *expectedJSON = @"[{&quot;lat&quot;:51.507400,&quot;lng&quot;:-0.127800}]";
    XCTAssertEqualObjects([_map markersJSON], expectedJSON);
    
    [loc release];
}

- (void)testMultipleObservationsInMap {
    Observation *o1 = [[[Observation alloc] init] autorelease];
    ObservationLocation *loc1 = [[[ObservationLocation alloc] init] autorelease];
    [loc1 setLatitude:[NSNumber numberWithDouble:51.5074]];
    [loc1 setLongitude:[NSNumber numberWithDouble:-0.1278]];
    [o1 setLocation:loc1];
    
    NSDateComponents *comp1 = [[[NSDateComponents alloc] init] autorelease];
    [comp1 setYear:2026];
    [comp1 setMonth:6];
    [comp1 setDay:11];
    [comp1 setHour:13];
    [comp1 setMinute:56];
    [comp1 setSecond:0];
    [o1 setCaptureDate:[[NSCalendar currentCalendar] dateFromComponents:comp1]];
    
    Observation *o2 = [[[Observation alloc] init] autorelease];
    
    Observation *o3 = [[[Observation alloc] init] autorelease];
    ObservationLocation *loc3 = [[[ObservationLocation alloc] init] autorelease];
    [loc3 setLatitude:[NSNumber numberWithDouble:48.8566]];
    [loc3 setLongitude:[NSNumber numberWithDouble:2.3522]];
    [o3 setLocation:loc3];
    
    NSDateComponents *comp3 = [[[NSDateComponents alloc] init] autorelease];
    [comp3 setYear:2026];
    [comp3 setMonth:6];
    [comp3 setDay:11];
    [comp3 setHour:15];
    [comp3 setMinute:30];
    [comp3 setSecond:0];
    [o3 setCaptureDate:[[NSCalendar currentCalendar] dateFromComponents:comp3]];
    
    NSArray *obs = [NSArray arrayWithObjects:o1, o2, o3, nil];
    [_map setObservations:obs];
    
    XCTAssertTrue([_map hasValidCoordinates]);
    XCTAssertEqualObjects([_map latitude], @"51.5074");
    XCTAssertEqualObjects([_map longitude], @"-0.1278");
    
    NSString *json = [_map markersJSON];
    XCTAssertTrue([json rangeOfString:@"{&quot;lat&quot;:51.507400,&quot;lng&quot;:-0.127800,&quot;title&quot;:&quot;Observation 1 at 13:56&quot;}"].location != NSNotFound);
    XCTAssertTrue([json rangeOfString:@"{&quot;lat&quot;:48.856600,&quot;lng&quot;:2.352200,&quot;title&quot;:&quot;Observation 3 at 15:30&quot;}"].location != NSNotFound);
    XCTAssertTrue([json rangeOfString:@"Observation 2"].location == NSNotFound);
}

@end
