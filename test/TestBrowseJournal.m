// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestBrowseJournal.m - Tests for the BrowseJournal component.
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
//
// Scoping/sort-order correctness needs a real DB round-trip, which real CI
// doesn't have (no Postgres service alongside make check - see
// .woodpecker.yaml/Containerfile). So these tests assert invariants that
// hold either way (empty/non-nil results, and "if data came back, it's
// correctly scoped and sorted") rather than fixed counts - verified directly
// against a real local Postgres during development; onthewing-czs.14 covers
// full staging verification.

#import "BrowseJournal.h"
#import "Session.h"
#import "Observer.h"
#import "JournalEntry.h"
#import "Observation.h"
#import "PhotoStorageMover.h"
#import "OTWApp.h"
#import <EOControl/EOControl.h>
#import <EOAccess/EOAccess.h>
#import <EOAccess/EOUtilities.h>
#import <XCTest/XCTest.h>

// Records DELETE requests instead of performing them, so delete-entry tests
// can count how many photo deletes were attempted.
@interface RecordingDeleteTransport : NSObject <PhotoStorageMoverTransport>
{
    NSMutableArray *_deletedURLs;
}
@property (nonatomic, readonly) NSArray *deletedURLs;
@end

@implementation RecordingDeleteTransport

- (id)init {
    self = [super init];
    if (self) {
        _deletedURLs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_deletedURLs release];
    [super dealloc];
}

- (NSArray *)deletedURLs {
    return _deletedURLs;
}

- (NSData *)sendRequest:(NSURLRequest *)request
                response:(NSURLResponse **)response
                   error:(NSError **)error {
    if ([[request HTTPMethod] isEqualToString:@"DELETE"]) {
        [_deletedURLs addObject:[request URL]];
    }
    if (response) {
        *response = [[[NSHTTPURLResponse alloc] initWithURL:[request URL]
                                                    statusCode:200
                                                   HTTPVersion:@"HTTP/1.1"
                                                  headerFields:nil] autorelease];
    }
    return [NSData data];
}

@end

@interface TestBrowseJournal : XCTestCase
{
    OTWApp *_app;
    WOContext *_ctx;
    BrowseJournal *_browse;
}
@end

@implementation TestBrowseJournal

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
    _browse = [[BrowseJournal alloc] initWithContext:_ctx];
}

- (void)tearDown {
    [_browse release]; _browse = nil;
    [_ctx release]; _ctx = nil;
    [_app release]; _app = nil;
}

- (void)testNoUserReturnsEmptyEntries {
    XCTAssertEqualObjects([_browse journalEntries], @[]);
    XCTAssertFalse([_browse hasAnyEntries]);
}

- (void)testUserWithNoEntriesReturnsEmpty {
    // A never-before-seen uid has zero rows whether or not a real DB is
    // reachable, so this is meaningful in both environments.
    Session *s = (Session *)[_ctx session];
    Observer *user = [[[Observer alloc] initWithUid:[[NSUUID UUID] UUIDString]
                                                name:@"Jane"
                                               email:@"jane@example.com"
                                           avatarUrl:nil
                                               token:nil] autorelease];
    [s setUser:user];

    XCTAssertEqual([[_browse journalEntries] count], (NSUInteger)0);
    XCTAssertFalse([_browse hasAnyEntries]);
}

- (void)testEntriesAreScopedToCurrentUserAndSortedDescendingWhenDataAvailable {
    Session *s = (Session *)[_ctx session];
    EOEditingContext *ec = [s editingContext];

    NSError *error = nil;
    [ec lock];
    NS_DURING {
        Observer *userA = [ec createAndInsertInstanceOfEntityNamed:@"Observer"];
        [userA setUid:[[NSUUID UUID] UUIDString]];
        Observer *userB = [ec createAndInsertInstanceOfEntityNamed:@"Observer"];
        [userB setUid:[[NSUUID UUID] UUIDString]];
        [ec saveChanges];

        JournalEntry *older = [ec createAndInsertInstanceOfEntityNamed:@"JournalEntry"];
        [older setObserver:userA];
        [older setDate:[NSDate dateWithTimeIntervalSince1970:10000]];
        JournalEntry *newer = [ec createAndInsertInstanceOfEntityNamed:@"JournalEntry"];
        [newer setObserver:userA];
        [newer setDate:[NSDate dateWithTimeIntervalSince1970:20000]];
        JournalEntry *otherUsers = [ec createAndInsertInstanceOfEntityNamed:@"JournalEntry"];
        [otherUsers setObserver:userB];
        [otherUsers setDate:[NSDate dateWithTimeIntervalSince1970:30000]];
        [ec saveChanges];

        [s setUser:userA];
    }
    NS_HANDLER {
        NSLog(@"testEntriesAreScopedToCurrentUserAndSortedDescendingWhenDataAvailable: no DB available to set up fixtures: %@", localException);
        error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    }
    NS_ENDHANDLER;
    [ec unlock];

    if (error != nil) {
        // No DB in this environment - can't meaningfully test scoping/sort
        // order, but journalEntries must still behave safely.
        XCTAssertEqualObjects([_browse journalEntries], @[]);
        return;
    }

    NSArray *results = [_browse journalEntries];
    XCTAssertEqual([results count], (NSUInteger)2);

    Observer *sessionUser = [(Session *)[_ctx session] user];
    NSDate *previousDate = nil;
    for (JournalEntry *entry in results) {
        XCTAssertEqualObjects([[entry observer] uid], [sessionUser uid]);
        if (previousDate != nil) {
            XCTAssertTrue([previousDate compare:[entry date]] != NSOrderedAscending, @"expected descending date order");
        }
        previousDate = [entry date];
    }
}

- (void)testCurrentEntryObservationsReturnsEmptyWhenNoCurrentEntry {
    XCTAssertEqualObjects([_browse currentEntryObservations], @[]);
}

- (void)testCurrentEntryObservationsMatchesFetchedEntryWhenDataAvailable {
    Session *s = (Session *)[_ctx session];
    EOEditingContext *ec = [s editingContext];

    NSError *error = nil;
    [ec lock];
    NS_DURING {
        Observer *user = [ec createAndInsertInstanceOfEntityNamed:@"Observer"];
        [user setUid:[[NSUUID UUID] UUIDString]];
        [ec saveChanges];

        JournalEntry *entry = [ec createAndInsertInstanceOfEntityNamed:@"JournalEntry"];
        [entry setObserver:user];
        [entry setDate:[NSDate date]];

        Observation *o1 = [ec createAndInsertInstanceOfEntityNamed:@"Observation"];
        [o1 setJournalEntry:entry];
        [o1 setCaptureDate:[NSDate date]];

        Observation *o2 = [ec createAndInsertInstanceOfEntityNamed:@"Observation"];
        [o2 setJournalEntry:entry];
        [o2 setCaptureDate:[NSDate date]];

        [ec saveChanges];

        [s setUser:user];
    }
    NS_HANDLER {
        NSLog(@"testCurrentEntryObservationsMatchesFetchedEntryWhenDataAvailable: no DB available to set up fixtures: %@", localException);
        error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    }
    NS_ENDHANDLER;
    [ec unlock];

    if (error != nil) {
        return;
    }

    JournalEntry *fetchedEntry = [[_browse journalEntries] firstObject];
    XCTAssertNotNil(fetchedEntry);
    [_browse setCurrentEntry:fetchedEntry];

    XCTAssertEqual([[_browse currentEntryObservations] count], (NSUInteger)2);
}

- (void)testCaptureReturnsCapturePageWithNewObservation {
    id page = [_browse capture];
    XCTAssertEqualObjects([page class], NSClassFromString(@"Capture"));
}

- (void)testDeleteEntryRemovesEntryAndDeletesEachObservationsPhoto {
    Session *s = (Session *)[_ctx session];
    EOEditingContext *ec = [s editingContext];

    NSError *error = nil;
    JournalEntry *entry = nil;
    NSString *entryId = nil;
    [ec lock];
    NS_DURING {
        Observer *user = [ec createAndInsertInstanceOfEntityNamed:@"Observer"];
        [user setUid:[[NSUUID UUID] UUIDString]];
        [ec saveChanges];

        entry = [ec createAndInsertInstanceOfEntityNamed:@"JournalEntry"];
        [entry setObserver:user];
        [entry setDate:[NSDate date]];

        Observation *obs1 = [ec createAndInsertInstanceOfEntityNamed:@"Observation"];
        [obs1 setJournalEntry:entry];
        [obs1 setCaptureDate:[NSDate date]];
        [obs1 setPhotoURLString:@"https://firebasestorage.googleapis.com/v0/b/test-bucket/o/journal%2Fabc%2Fentry%2Fphoto1.jpg?alt=media"];

        Observation *obs2 = [ec createAndInsertInstanceOfEntityNamed:@"Observation"];
        [obs2 setJournalEntry:entry];
        [obs2 setCaptureDate:[NSDate date]];
        [obs2 setPhotoURLString:@"https://firebasestorage.googleapis.com/v0/b/test-bucket/o/journal%2Fabc%2Fentry%2Fphoto2.jpg?alt=media"];

        [ec saveChanges];
        entryId = [[entry journalEntryId] copy];

        [s setUser:user];
    }
    NS_HANDLER {
        NSLog(@"testDeleteEntryRemovesEntryAndDeletesEachObservationsPhoto: no DB available to set up fixtures: %@", localException);
        error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    }
    NS_ENDHANDLER;
    [ec unlock];

    if (error != nil) {
        // No DB in this environment - nothing meaningful to assert.
        return;
    }

    // Re-fetch through the same path the real UI uses (BrowseJournal
    // -journalEntries) rather than reusing the freshly-inserted `entry`
    // instance directly: a bare, non-refetched object's to-many
    // relationship ivar is never populated (see -journalEntries' own
    // comments on why it avoids relying on relationship faulting for
    // objects that aren't EC-fetched).
    JournalEntry *fetchedEntry = [[_browse journalEntries] firstObject];
    XCTAssertNotNil(fetchedEntry);

    RecordingDeleteTransport *transport = [[[RecordingDeleteTransport alloc] init] autorelease];
    PhotoStorageMover *mover = [[[PhotoStorageMover alloc] initWithBucket:@"test-bucket"
                                                                 apiBaseURL:@"http://emulator.local:9199"
                                                      serviceAccountKeyPath:nil
                                                                  transport:transport] autorelease];
    [_browse setPhotoStorageMover:mover];
    [_browse setCurrentEntry:fetchedEntry];

    [_browse deleteEntry];

    XCTAssertEqual([[transport deletedURLs] count], (NSUInteger)2);

    for (JournalEntry *remaining in [_browse journalEntries]) {
        XCTAssertNotEqualObjects([remaining journalEntryId], entryId);
    }
    [entryId release];
}

- (void)testDeleteEntryNoOpsWhenNotOwnedBySessionUser {
    Session *s = (Session *)[_ctx session];
    EOEditingContext *ec = [s editingContext];

    NSError *error = nil;
    JournalEntry *entry = nil;
    [ec lock];
    NS_DURING {
        Observer *owner = [ec createAndInsertInstanceOfEntityNamed:@"Observer"];
        [owner setUid:[[NSUUID UUID] UUIDString]];
        Observer *otherUser = [ec createAndInsertInstanceOfEntityNamed:@"Observer"];
        [otherUser setUid:[[NSUUID UUID] UUIDString]];
        [ec saveChanges];

        entry = [ec createAndInsertInstanceOfEntityNamed:@"JournalEntry"];
        [entry setObserver:owner];
        [entry setDate:[NSDate date]];
        [ec saveChanges];

        [s setUser:otherUser];
    }
    NS_HANDLER {
        NSLog(@"testDeleteEntryNoOpsWhenNotOwnedBySessionUser: no DB available to set up fixtures: %@", localException);
        error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    }
    NS_ENDHANDLER;
    [ec unlock];

    if (error != nil) {
        return;
    }

    RecordingDeleteTransport *transport = [[[RecordingDeleteTransport alloc] init] autorelease];
    PhotoStorageMover *mover = [[[PhotoStorageMover alloc] initWithBucket:@"test-bucket"
                                                                 apiBaseURL:@"http://emulator.local:9199"
                                                      serviceAccountKeyPath:nil
                                                                  transport:transport] autorelease];
    [_browse setPhotoStorageMover:mover];
    [_browse setCurrentEntry:entry];

    [_browse deleteEntry];

    XCTAssertEqual([[transport deletedURLs] count], (NSUInteger)0);
    XCTAssertFalse([[ec deletedObjects] containsObject:entry]);
}

@end
