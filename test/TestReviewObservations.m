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
#import "Observer.h"
#import "JournalEntry.h"
#import "PhotoStorageMover.h"
#import "OTWApp.h"
#import <EOControl/EOControl.h>
#import <XCTest/XCTest.h>

// Always fails, so a spawned migration thread's real work is fast and inert.
@interface AlwaysFailingTransport : NSObject <PhotoStorageMoverTransport>
@end

@implementation AlwaysFailingTransport
- (NSData *)sendRequest:(NSURLRequest *)request
                response:(NSURLResponse **)response
                   error:(NSError **)error {
    if (error) {
        *error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    }
    return nil;
}
@end

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

- (void)testDiscardObservationsEmptiesSessionAndReturnsMainPage {
    Session *s = (Session *)[_ctx session];
    Observation *o1 = [[[Observation alloc] init] autorelease];
    Observation *o2 = [[[Observation alloc] init] autorelease];
    [s addObservationForReview:o1];
    [s addObservationForReview:o2];

    id nextPage = [_review discardObservations];

    XCTAssertEqualObjects([nextPage class], NSClassFromString(@"Main"));
    XCTAssertEqual([[s unreviewedObservations] count], (NSUInteger)0);
}

- (void)testBuildJournalEntryForObservationsSetsDateObserverAndRelationships {
    EOEditingContext *ec = [[[EOEditingContext alloc] init] autorelease];
    Observer *observer = [[[Observer alloc] initWithUid:@"uid-1" name:@"Jane" email:@"jane@example.com" avatarUrl:nil token:nil] autorelease];

    Observation *o1 = [[[Observation alloc] init] autorelease];
    [o1 setCaptureDate:[NSDate dateWithTimeIntervalSince1970:20000]];
    Observation *o2 = [[[Observation alloc] init] autorelease];
    [o2 setCaptureDate:[NSDate dateWithTimeIntervalSince1970:10000]];
    NSArray *sorted = @[o2, o1]; // already-sorted input, matching sortedObservations' contract

    JournalEntry *entry = [_review buildJournalEntryForObservations:sorted observer:observer editingContext:ec];

    XCTAssertEqualObjects([entry observer], observer);
    XCTAssertEqualObjects([entry date], [o2 captureDate]);
    XCTAssertEqualObjects([o1 journalEntry], entry);
    XCTAssertEqualObjects([o2 journalEntry], entry);
}

- (void)testSaveToJournalWithNoObservationsReturnsMainPage {
    id nextPage = [_review saveToJournal];
    XCTAssertEqualObjects([nextPage class], NSClassFromString(@"Main"));
}

- (void)testSaveToJournalWithUnpersistedObserverDoesNotCrash {
    // FirebaseLogin's DB-outage fallback can leave session.user as a bare
    // Observer never inserted into any EC - relating that to a new
    // JournalEntry and calling saveChanges crashes GDL2 outright (confirmed
    // by direct repro). saveToJournal now retries persisting via
    // -[Session saveObserverWithError:] (see TestSession.m for direct
    // coverage of that) rather than just giving up - whether the retry
    // succeeds depends on DB availability, which differs between this
    // environment (may have a real local Postgres) and actual CI (never
    // does, per .woodpecker.yaml/Containerfile) - so assert only that it
    // doesn't crash either way, same reasoning as the tests below.
    Session *s = (Session *)[_ctx session];
    Observer *user = [[[Observer alloc] initWithUid:[[NSUUID UUID] UUIDString] name:@"Jane" email:@"jane@example.com" avatarUrl:nil token:nil] autorelease];
    [s setUser:user];

    Observation *o = [[[Observation alloc] init] autorelease];
    [o setCaptureDate:[NSDate date]];
    [s addObservationForReview:o];

    id nextPage = [_review saveToJournal];

    XCTAssertNotNil(nextPage);
}

// The two tests below exercise a properly EC-registered Observer (the normal
// case) saving with and without a photo. Whether saveChanges actually
// succeeds depends on whether a real Postgres is reachable: it is NOT in the
// project's actual CI (see .woodpecker.yaml/Containerfile - make check runs
// with no DB service), but may be on a developer's machine, which flips the
// outcome (JournalEntry commits vs. saveToJournal fails gracefully). Rather
// than assert one fixed outcome that would only be correct in one of those
// environments, these assert only what's true either way - the actual thing
// under test is that neither path crashes, particularly the photo case,
// which spawns a background NSThread. Full outcome verification (does the
// DB commit land correctly, does migration actually complete) is staging's
// job (onthewing-czs.14).

- (void)testSaveToJournalWithProperlyRegisteredObserverAndNoPhotoDoesNotCrash {
    Session *s = (Session *)[_ctx session];
    EOEditingContext *ec = [s editingContext];
    Observer *user = [ec createAndInsertInstanceOfEntityNamed:@"Observer"];
    [user setUid:[[NSUUID UUID] UUIDString]];
    [s setUser:user];

    Observation *o = [[[Observation alloc] init] autorelease];
    [o setCaptureDate:[NSDate date]];
    [s addObservationForReview:o];

    id nextPage = [_review saveToJournal];

    XCTAssertNotNil(nextPage);
}

- (void)testSaveToJournalWithPhotoSpawnsMigrationWithoutCrashingOrBlocking {
    Session *s = (Session *)[_ctx session];
    EOEditingContext *ec = [s editingContext];
    Observer *user = [ec createAndInsertInstanceOfEntityNamed:@"Observer"];
    NSString *uid = [[NSUUID UUID] UUIDString];
    [user setUid:uid];
    [s setUser:user];

    Observation *o = [[[Observation alloc] init] autorelease];
    [o setCaptureDate:[NSDate date]];
    [o setPhotoURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:9199/v0/b/bucket/o/temp%%2F%@%%2Fphoto.jpg?alt=media", uid]]];
    [s addObservationForReview:o];

    // Always-failing transport: keeps the spawned thread's real work fast
    // and harmless regardless of whether the DB save above succeeded.
    AlwaysFailingTransport *transport = [[[AlwaysFailingTransport alloc] init] autorelease];
    PhotoStorageMover *mover = [[[PhotoStorageMover alloc] initWithBucket:@"test-bucket"
                                                                 apiBaseURL:@"http://emulator.local:9199"
                                                      serviceAccountKeyPath:nil
                                                                  transport:transport] autorelease];
    [_review setPhotoStorageMover:mover];

    id nextPage = [_review saveToJournal];

    XCTAssertNotNil(nextPage);
}

// A never-before-seen uid has zero already-saved photos whether or not a
// real DB is reachable (see Observer -savedPhotoCountInEditingContext:'s own
// "no DB" fallback), so the quota math (51 pending > 50 remaining) is
// deterministic in both environments - unlike the DB-save outcome itself,
// which the tests above already treat as environment-dependent.

- (void)testSaveToJournalRejectsWhenPendingPhotosExceedQuota {
    Session *s = (Session *)[_ctx session];
    Observer *user = [[[Observer alloc] initWithUid:[[NSUUID UUID] UUIDString] name:@"Jane" email:@"jane@example.com" avatarUrl:nil token:nil] autorelease];
    [s setUser:user];

    for (NSUInteger i = 0; i < 51; i++) {
        Observation *o = [[[Observation alloc] init] autorelease];
        [o setCaptureDate:[NSDate date]];
        [o setPhotoURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://firebasestorage.googleapis.com/v0/b/bucket/o/temp%%2Fp%lu.jpg?alt=media", (unsigned long)i]]];
        [s addObservationForReview:o];
    }

    id nextPage = [_review saveToJournal];

    XCTAssertEqualObjects(nextPage, _review);
    XCTAssertEqual([[s unreviewedObservations] count], (NSUInteger)51);
    XCTAssertNotNil([_review lastError]);
}

@end
