// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestReviewObservations.m - Tests for the ReviewObservations component.
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

#import "ReviewObservations.h"
#import "Observation.h"
#import "ObservationLocation.h"
#import "Session.h"
#import "OTWApp.h"
#import <XCTest/XCTest.h>

@interface TestReviewObservations : XCTestCase
{
    OTWApp *_app;
    WOContext *_ctx;
    ReviewObservations *_review;
}
@end

@implementation TestReviewObservations

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
    _app = [[OTWApp alloc] init];
    _ctx = [[self dummyContext] retain];
    _review = [[ReviewObservations alloc] initWithContext:_ctx];
}

- (void)tearDown {
    [_review release]; _review = nil;
    [_ctx release]; _ctx = nil;
    [_app release]; _app = nil;
}

- (void)testSortedObservationsIsChronological {
    Session *s = (Session *)[_ctx session];
    
    Observation *o1 = [[[Observation alloc] init] autorelease];
    [o1 setCaptureDate:[NSDate dateWithTimeIntervalSince1970:20000]];
    
    Observation *o2 = [[[Observation alloc] init] autorelease];
    [o2 setCaptureDate:[NSDate dateWithTimeIntervalSince1970:10000]];
    
    Observation *o3 = [[[Observation alloc] init] autorelease];
    [o3 setCaptureDate:[NSDate dateWithTimeIntervalSince1970:30000]];
    
    [s addObservationForReview:o1];
    [s addObservationForReview:o2];
    [s addObservationForReview:o3];
    
    NSArray *sorted = [_review sortedObservations];
    XCTAssertEqual([sorted count], (NSUInteger)3);
    XCTAssertEqualObjects([sorted objectAtIndex:0], o2);
    XCTAssertEqualObjects([sorted objectAtIndex:1], o1);
    XCTAssertEqualObjects([sorted objectAtIndex:2], o3);
}

- (void)testFormattedCaptureDate {
    Observation *o = [[[Observation alloc] init] autorelease];
    
    // Test for today
    [o setCaptureDate:[NSDate date]];
    [_review setCurrentObservation:o];
    
    NSString *todayStr = [_review formattedCaptureDate];
    XCTAssertEqual([todayStr length], (NSUInteger)5);
    XCTAssertTrue([todayStr rangeOfString:@":"].location != NSNotFound);
    
    // Test for a past date: 2026-06-10 13:56:00 Local/UTC
    NSDateComponents *comp = [[[NSDateComponents alloc] init] autorelease];
    [comp setYear:2026];
    [comp setMonth:6];
    [comp setDay:10];
    [comp setHour:13];
    [comp setMinute:56];
    [comp setSecond:0];
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *pastDate = [cal dateFromComponents:comp];
    
    [o setCaptureDate:pastDate];
    [_review setCurrentObservation:o];
    
    NSString *pastStr = [_review formattedCaptureDate];
    XCTAssertEqualObjects(pastStr, @"13:56 on 2026-06-10");
}

- (void)testHasAnyLocation {
    Session *s = (Session *)[_ctx session];
    XCTAssertFalse([_review hasAnyLocation]);
    
    Observation *o1 = [[[Observation alloc] init] autorelease];
    [o1 setCaptureDate:[NSDate dateWithTimeIntervalSince1970:10000]];
    [s addObservationForReview:o1];
    XCTAssertFalse([_review hasAnyLocation]);
    
    Observation *o2 = [[[Observation alloc] init] autorelease];
    [o2 setCaptureDate:[NSDate dateWithTimeIntervalSince1970:20000]];
    ObservationLocation *loc = [[[ObservationLocation alloc] init] autorelease];
    [loc setLatitude:[NSNumber numberWithDouble:51.5074]];
    [loc setLongitude:[NSNumber numberWithDouble:-0.1278]];
    [o2 setLocation:loc];
    [s addObservationForReview:o2];
    
    XCTAssertTrue([_review hasAnyLocation]);
}

- (void)testDeleteLastObservationReturnsMainPage {
    Session *s = (Session *)[_ctx session];
    Observation *o = [[[Observation alloc] init] autorelease];
    [s addObservationForReview:o];
    
    [_review setCurrentObservation:o];
    id nextPage = [_review deleteObservation];
    
    XCTAssertEqualObjects([nextPage class], NSClassFromString(@"Main"));
    XCTAssertFalse([[s unreviewedObservations] containsObject:o]);
}

- (void)testDeleteObservationWhenOthersRemainReturnsReviewPage {
    Session *s = (Session *)[_ctx session];
    Observation *o1 = [[[Observation alloc] init] autorelease];
    Observation *o2 = [[[Observation alloc] init] autorelease];
    [s addObservationForReview:o1];
    [s addObservationForReview:o2];
    
    [_review setCurrentObservation:o1];
    id nextPage = [_review deleteObservation];
    
    XCTAssertEqualObjects(nextPage, _review);
    XCTAssertFalse([[s unreviewedObservations] containsObject:o1]);
    XCTAssertTrue([[s unreviewedObservations] containsObject:o2]);
}

@end
