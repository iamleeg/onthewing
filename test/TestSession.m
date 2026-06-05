// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestSession.m - Tests for the Session class
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

#import "Session.h"
#import "OTWApp.h"

#import "Observation.h"

#import <XCTest/XCTest.h>

@interface TestSession : XCTestCase
{
  Session *_s;
}
@end

@implementation TestSession

- (void)setUp {
  _s = [[Session alloc] init];
}

- (void)tearDown {
  [_s release];
}

- (void)testSessionIDsInCookies {
  XCTAssertTrue([_s storesIDsInCookies]);
}

- (void)testSessionIDsInURLs {
  XCTAssertFalse([_s storesIDsInURLs]);
}

- (void)testAddingAnUnreviewedObservation {
  Observation *o = [[Observation alloc] init];
  [_s addObservationForReview:o];
  XCTAssertTrue([[_s unreviewedObservations] containsObject:o]);
  [o release];
}

@end
