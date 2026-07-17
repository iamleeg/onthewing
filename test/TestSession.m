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
#import "OTWFlashMessage.h"

#import "Observation.h"
#import "Observer.h"
#import <EOControl/EOControl.h>
#import <EOAccess/EOAccess.h>
#import <EOAccess/EOUtilities.h>

#import <XCTest/XCTest.h>

@interface TestSession : XCTestCase
{
  OTWApp *_app;
  Session *_s;
}
@end

@implementation TestSession

- (void)setUp {
  _app = [[OTWApp alloc] init];
  _s = [[Session alloc] init];
}

- (void)tearDown {
  [_s release];
  [_app release];
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

- (void)testSaveObserverWithErrorReturnsNilAndSetsErrorWhenNoUser {
  NSError *error = nil;
  XCTAssertNil([_s saveObserverWithError:&error]);
  XCTAssertNotNil(error);
}

- (void)testSaveObserverWithErrorReturnsAlreadyPersistedUserUnchanged {
  EOEditingContext *ec = [_s editingContext];
  Observer *user = [ec createAndInsertInstanceOfEntityNamed:@"Observer"];
  [user setUid:[[NSUUID UUID] UUIDString]];
  [_s setUser:user];

  NSError *error = nil;
  Observer *result = [_s saveObserverWithError:&error];

  XCTAssertEqualObjects(result, user);
  XCTAssertEqualObjects([_s user], user);
  XCTAssertNil(error);
}

- (void)testSaveObserverWithErrorHandlesUnpersistedUserWithoutCrashing {
  // Whether the DB retry succeeds depends on environment (this dev machine
  // may have a real local Postgres; actual CI never does - see
  // TestReviewObservations.m for the same reasoning), so this only asserts
  // the safety property (no crash) and the nil-result-implies-error contract,
  // regardless of which branch actually runs.
  Observer *bareUser = [[[Observer alloc] initWithUid:[[NSUUID UUID] UUIDString]
                                                  name:@"Jane"
                                                 email:@"jane@example.com"
                                             avatarUrl:nil
                                                 token:nil] autorelease];
  [_s setUser:bareUser];

  NSError *error = nil;
  Observer *result = [_s saveObserverWithError:&error];

  if (result == nil) {
    XCTAssertNotNil(error);
  } else {
    XCTAssertNil(error);
  }
}

- (void)testSetFlashMessageAndConsumeBehaveAsReadOnce {
  OTWFlashMessage *msg = [[OTWFlashMessage alloc] initWithStringValue:@"Hello" severityLevel:OTWFlashMessageSeverityInfo];
  [_s setFlashMessage:msg];
  [msg release];

  OTWFlashMessage *consumed1 = [_s consumeFlashMessage];
  XCTAssertNotNil(consumed1);
  XCTAssertEqualObjects(consumed1.stringValue, @"Hello");
  XCTAssertEqual(consumed1.severityLevel, OTWFlashMessageSeverityInfo);

  OTWFlashMessage *consumed2 = [_s consumeFlashMessage];
  XCTAssertNil(consumed2);
}

- (void)testSerializationOfFlashMessage {
  OTWFlashMessage *msg = [[OTWFlashMessage alloc] initWithStringValue:@"Error" severityLevel:OTWFlashMessageSeverityError];
  [_s setFlashMessage:msg];
  [msg release];

  NSDictionary *state = [_s stateDictionary];
  
  Session *s2 = [[Session alloc] init];
  [s2 restoreFromStateDictionary:state];

  OTWFlashMessage *restored = [s2 consumeFlashMessage];
  XCTAssertNotNil(restored);
  XCTAssertEqualObjects(restored.stringValue, @"Error");
  XCTAssertEqual(restored.severityLevel, OTWFlashMessageSeverityError);
  
  [s2 release];
}

@end
