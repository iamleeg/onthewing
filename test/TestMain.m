// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestMain.m - Tests for the Main class
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

#import "Capture.h"
#import "Main.h"
#import "Observation.h"
#import "ReviewObservations.h"
#import "BrowseJournal.h"
#import "OTWApp.h"
#import "Session.h"
#import <XCTest/XCTest.h>

@interface TestMain : XCTestCase
{
  OTWApp *_app;
  WORequest *_req;
  WOContext *_ctx;
  Session *_s;
  Main *_m;
}
@end

@implementation TestMain

- (void)setUp {
  _app = [[OTWApp alloc] init];
  _req = [[WORequest alloc] initWithMethod:@"GET"
                                       uri:@"/"
                               httpVersion:@"HTTP/1.1"
                                   headers:nil
                                   content:nil
                                  userInfo:nil];
  _ctx = [[WOContext alloc] initWithRequest:_req];
  _s = (Session *)[_ctx session];
  _m = [[Main alloc] initWithContext:_ctx];

}
- (void)tearDown {
  [_m release]; _m = nil;
  [_ctx release]; _ctx = nil;
  _s = nil;
  [_req release]; _req = nil;
  [_app release]; _app = nil;
}

- (void)testMainReturnsCapturePage {
  Capture *capture = [_m capture];
  XCTAssertEqualObjects([capture class], [Capture class]);
  XCTAssertNotNil([[capture observation] captureDate]);
}

- (void)testMainWithEmptySessionHasNoObservations {
  XCTAssertFalse([_m hasObservations]);
}

- (void)testMainWithPendingObservationsInSessionHasObservations {
  Observation *o = [[[Observation alloc] init] autorelease];
  [_s addObservationForReview:o];
  XCTAssertTrue([_m hasObservations]);
}

- (void)testMainWithOnePendingObservationReportsIt {
  Observation *o = [[[Observation alloc] init] autorelease];
  [_s addObservationForReview:o];
  XCTAssertEqualObjects([_m reportPendingObservations], @"There's an observation you can add to your journal!");
}

- (void)testMainWithTwoPendingObservationsReportsThem {
  Observation *o1 = [[[Observation alloc] init] autorelease];
  Observation *o2 = [[[Observation alloc] init] autorelease];
  [_s addObservationForReview:o1];
  [_s addObservationForReview:o2];
  XCTAssertEqualObjects([_m reportPendingObservations], @"You have 2 observations you can add to your journal!");
}

- (void)testReviewObservationsAction {
  id page = [_m reviewObservations];
  XCTAssertEqualObjects([page class], [ReviewObservations class]);
}

- (void)testBrowseJournalAction {
  id page = [_m browseJournal];
  XCTAssertEqualObjects([page class], [BrowseJournal class]);
}

- (void)testIsAppReadyReflectsDatabaseSchemaReady {
  [_app setDatabaseSchemaReady:YES];
  XCTAssertTrue([_m isAppReady]);

  [_app setDatabaseSchemaReady:NO];
  XCTAssertFalse([_m isAppReady]);
}
@end
