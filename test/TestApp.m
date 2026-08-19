// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestApp.m - Tests for the OTWApp class
// Copyright (C) 2026 Graham Lee
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 4 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

#import "TestOTWApp.h"
#import <EOAccess/EOAccess.h>
#import <XCTest/XCTest.h>

@interface TestApp : XCTestCase
{
  OTWApp *_app;
}
@end

@implementation TestApp

- (void)setUp {
  _app = [[TestOTWApp alloc] init];
}

- (void)tearDown {
  [_app release];
  _app = nil;
}

- (void)testSessionTimeOut {
  NSNumber *timeout = [OTWApp sessionTimeOut];
  XCTAssertEqualObjects(timeout, @60);
}

- (void)testDatabaseSchemaReadyIsSettable {
  [_app setDatabaseSchemaReady:YES];
  XCTAssertTrue([_app isDatabaseSchemaReady]);

  [_app setDatabaseSchemaReady:NO];
  XCTAssertFalse([_app isDatabaseSchemaReady]);
}

- (void)testInitSetsDefaultRequestHandler {
  NSString *directActionHandlerKey =
      [[_app class] directActionRequestHandlerKey];
  WORequestHandler *handler = [_app requestHandlerForKey:directActionHandlerKey];
  XCTAssertEqualObjects([_app defaultRequestHandler], handler);
}

- (void)testInitSetsMessageEncoding {
  XCTAssertEqual([WOMessage defaultEncoding],
                 (NSStringEncoding)NSUTF8StringEncoding);
}

- (void)testModelHasFourEntities {
  EOModel *model = [[EOModelGroup defaultGroup] modelNamed:@"OnTheWing"];
  XCTAssertNotNil(model);
  XCTAssertEqual([[model entities] count], (NSUInteger)4);
  XCTAssertNotNil([model entityNamed:@"Observer"]);
  XCTAssertNotNil([model entityNamed:@"Observation"]);
  XCTAssertNotNil([model entityNamed:@"JournalEntry"]);
}

- (void)testObservationJournalEntryRelationshipIsToOne {
  EOModel *model = [[EOModelGroup defaultGroup] modelNamed:@"OnTheWing"];
  EOEntity *observationEntity = [model entityNamed:@"Observation"];
  EORelationship *rel = [observationEntity relationshipNamed:@"journalEntry"];
  XCTAssertNotNil(rel);
  XCTAssertFalse([rel isToMany]);
  XCTAssertEqualObjects([[rel destinationEntity] name], @"JournalEntry");
}

- (void)testJournalEntryObservationsRelationshipIsToManyCascade {
  EOModel *model = [[EOModelGroup defaultGroup] modelNamed:@"OnTheWing"];
  EOEntity *journalEntryEntity = [model entityNamed:@"JournalEntry"];
  EORelationship *rel = [journalEntryEntity relationshipNamed:@"observations"];
  XCTAssertNotNil(rel);
  XCTAssertTrue([rel isToMany]);
  XCTAssertEqualObjects([[rel destinationEntity] name], @"Observation");
  XCTAssertEqual([rel deleteRule], (EODeleteRule)EODeleteRuleCascade);
}

- (void)testJournalEntryObservationsIsInverseOfObservationJournalEntry {
  EOModel *model = [[EOModelGroup defaultGroup] modelNamed:@"OnTheWing"];
  EORelationship *toOne = [[model entityNamed:@"Observation"] relationshipNamed:@"journalEntry"];
  EORelationship *toMany = [[model entityNamed:@"JournalEntry"] relationshipNamed:@"observations"];
  XCTAssertEqualObjects([toOne inverseRelationship], toMany);
  XCTAssertEqualObjects([toMany inverseRelationship], toOne);
}

- (void)testJournalEntryObserverRelationshipIsToOne {
  EOModel *model = [[EOModelGroup defaultGroup] modelNamed:@"OnTheWing"];
  EOEntity *journalEntryEntity = [model entityNamed:@"JournalEntry"];
  EORelationship *rel = [journalEntryEntity relationshipNamed:@"observer"];
  XCTAssertNotNil(rel);
  XCTAssertFalse([rel isToMany]);
  XCTAssertEqualObjects([[rel destinationEntity] name], @"Observer");
}

- (void)testObserverJournalEntriesRelationshipIsToManyNotCascade {
  EOModel *model = [[EOModelGroup defaultGroup] modelNamed:@"OnTheWing"];
  EOEntity *observerEntity = [model entityNamed:@"Observer"];
  EORelationship *rel = [observerEntity relationshipNamed:@"journalEntries"];
  XCTAssertNotNil(rel);
  XCTAssertTrue([rel isToMany]);
  XCTAssertEqualObjects([[rel destinationEntity] name], @"JournalEntry");
  XCTAssertNotEqual([rel deleteRule], (EODeleteRule)EODeleteRuleCascade);
}

- (void)testObservationObserverRelationshipIsToOne {
  EOModel *model = [[EOModelGroup defaultGroup] modelNamed:@"OnTheWing"];
  EOEntity *observationEntity = [model entityNamed:@"Observation"];
  EORelationship *rel = [observationEntity relationshipNamed:@"observer"];
  XCTAssertNotNil(rel);
  XCTAssertFalse([rel isToMany]);
  XCTAssertEqualObjects([[rel destinationEntity] name], @"Observer");
}

- (void)testObserverObservationsRelationshipIsToManyCascade {
  EOModel *model = [[EOModelGroup defaultGroup] modelNamed:@"OnTheWing"];
  EOEntity *observerEntity = [model entityNamed:@"Observer"];
  EORelationship *rel = [observerEntity relationshipNamed:@"observations"];
  XCTAssertNotNil(rel);
  XCTAssertTrue([rel isToMany]);
  XCTAssertEqualObjects([[rel destinationEntity] name], @"Observation");
  XCTAssertEqual([rel deleteRule], (EODeleteRule)EODeleteRuleCascade);
}

- (void)testObservationAndJournalEntryHavePrimaryKeys {
  EOModel *model = [[EOModelGroup defaultGroup] modelNamed:@"OnTheWing"];
  EOEntity *observationEntity = [model entityNamed:@"Observation"];
  EOEntity *journalEntryEntity = [model entityNamed:@"JournalEntry"];
  XCTAssertEqual([[observationEntity primaryKeyAttributeNames] count], (NSUInteger)1);
  XCTAssertEqualObjects([[observationEntity primaryKeyAttributeNames] firstObject], @"observationId");
  XCTAssertEqual([[journalEntryEntity primaryKeyAttributeNames] count], (NSUInteger)1);
  XCTAssertEqualObjects([[journalEntryEntity primaryKeyAttributeNames] firstObject], @"journalEntryId");
}

- (void)testAttemptSchemaInitializationResilience {
  // attemptSchemaInitialization is called during [OTWApp init].
  // If the resilient NS_DURING block works, it will catch the GDL2 exception
  // (Tried to add nil to array) internally without bubbling up.
  // We explicitly call it here to ensure it doesn't throw.
  XCTAssertNoThrow([_app attemptSchemaInitialization]);
}

@end
@interface TestApp (GDL2Bug)

@end
@implementation TestApp (GDL2Bug)
@end
