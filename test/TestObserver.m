// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestObserver.m - Tests for the Observer class and its session storage
// Copyright (C) 2026 Graham Lee
//

#import "Observer.h"
#import "Session.h"
#import "JournalEntry.h"
#import "Observation.h"
#import "TestOTWApp.h"
#import <EOControl/EOControl.h>
#import <EOAccess/EOAccess.h>
#import <XCTest/XCTest.h>

@interface TestObserver : XCTestCase
@end

@implementation TestObserver

- (void)testObserverInitialization {
    Observer *user = [[Observer alloc] initWithUid:@"test-uid-123"
                                      name:@"John Doe"
                                     email:@"john@example.com"
                                 avatarUrl:@"http://example.com/avatar.jpg"
                                     token:@"test-token-456"];
    
    XCTAssertEqualObjects([user uid], @"test-uid-123");
    XCTAssertEqualObjects([user name], @"John Doe");
    XCTAssertEqualObjects([user email], @"john@example.com");
    XCTAssertEqualObjects([user avatarUrl], @"http://example.com/avatar.jpg");
    XCTAssertEqualObjects([user token], @"test-token-456");
    
    [user release];
}

- (void)testSessionStoresObserver {
    Session *session = [[Session alloc] init];
    XCTAssertNil([session user]);
    
    Observer *user = [[Observer alloc] initWithUid:@"test-uid"
                                      name:@"Jane Doe"
                                     email:@"jane@example.com"
                                 avatarUrl:nil
                                     token:@"token"];
    [session setUser:user];
    XCTAssertEqualObjects([session user], user);
    
    [session setUser:nil];
    XCTAssertNil([session user]);
    
    [user release];
    [session release];
}

- (void)testRemainingPhotoQuotaForNeverSeenObserverIsFullLimit {
    // A never-before-seen uid has zero saved photos whether or not a real DB
    // is reachable, so this is meaningful in both environments.
    OTWApp *app = [[TestOTWApp alloc] init];
    EOEditingContext *ec = [[[EOEditingContext alloc] init] autorelease];
    Observer *user = [[[Observer alloc] initWithUid:[[NSUUID UUID] UUIDString]
                                                name:@"Jane"
                                               email:@"jane@example.com"
                                           avatarUrl:nil
                                               token:nil] autorelease];

    XCTAssertEqual([user savedPhotoCountInEditingContext:ec], (NSUInteger)0);
    XCTAssertEqual([user remainingPhotoQuotaInEditingContext:ec], kFreeTierPhotoLimit);

    [app release];
}

- (void)testSavedPhotoCountOnlyCountsSavedObservationsWithAPhotoWhenDataAvailable {
    OTWApp *app = [[TestOTWApp alloc] init];
    EOEditingContext *ec = [[[EOEditingContext alloc] init] autorelease];

    NSError *error = nil;
    Observer *user = nil;
    [ec lock];
    NS_DURING {
        user = [ec createAndInsertInstanceOfEntityNamed:@"Observer"];
        [user setUid:[[NSUUID UUID] UUIDString]];
        [ec saveChanges];

        JournalEntry *entry = [ec createAndInsertInstanceOfEntityNamed:@"JournalEntry"];
        [entry setObserver:user];
        if (![user journalEntries]) { [user setJournalEntries:[NSMutableArray array]]; }
        [[user journalEntries] addObject:entry];

        for (NSUInteger i = 0; i < 3; i++) {
            Observation *withPhoto = [ec createAndInsertInstanceOfEntityNamed:@"Observation"];
            [withPhoto setJournalEntry:entry];
        if (![entry observations]) { [entry setObservations:[NSMutableArray array]]; }
        [[entry observations] addObject:withPhoto];
        [withPhoto setObserver:[entry observer]];
        if (![[entry observer] observations]) { [[entry observer] setObservations:[NSMutableArray array]]; }
        [[[entry observer] observations] addObject:withPhoto];
            [withPhoto setCaptureDate:[NSDate date]];
            [withPhoto setPhotoURLString:[NSString stringWithFormat:@"https://firebasestorage.googleapis.com/v0/b/bucket/o/journal%%2F%lu.jpg?alt=media", (unsigned long)i]];
        }

        Observation *withoutPhoto = [ec createAndInsertInstanceOfEntityNamed:@"Observation"];
        [withoutPhoto setJournalEntry:entry];
        if (![entry observations]) { [entry setObservations:[NSMutableArray array]]; }
        [[entry observations] addObject:withoutPhoto];
        [withoutPhoto setObserver:[entry observer]];
        if (![[entry observer] observations]) { [[entry observer] setObservations:[NSMutableArray array]]; }
        [[[entry observer] observations] addObject:withoutPhoto];
        [withoutPhoto setCaptureDate:[NSDate date]];

        [ec saveChanges];
    }
    NS_HANDLER {
        NSLog(@"testSavedPhotoCountOnlyCountsSavedObservationsWithAPhotoWhenDataAvailable: no DB available to set up fixtures: %@", localException);
        error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    }
    NS_ENDHANDLER;
    [ec unlock];

    if (error != nil) {
        [app release];
        return;
    }

    XCTAssertEqual([user savedPhotoCountInEditingContext:ec], (NSUInteger)3);
    XCTAssertEqual([user remainingPhotoQuotaInEditingContext:ec], (NSUInteger)(kFreeTierPhotoLimit - 3));

    [app release];
}

- (void)testRemainingPhotoQuotaIsUnlimitedForPremiumUser {
    OTWApp *app = [[TestOTWApp alloc] init];
    EOEditingContext *ec = [[[EOEditingContext alloc] init] autorelease];
    Observer *user = [[[Observer alloc] initWithUid:[[NSUUID UUID] UUIDString]
                                                name:@"Premium"
                                               email:@"premium@example.com"
                                           avatarUrl:nil
                                               token:nil] autorelease];
    [user setIsPremium:@(YES)];

    XCTAssertEqual([user remainingPhotoQuotaInEditingContext:ec], (NSUInteger)NSUIntegerMax);
    [app release];
}

- (void)testRemainingPhotoQuotaAtBoundaryCondition {
    OTWApp *app = [[TestOTWApp alloc] init];
    EOEditingContext *ec = [[[EOEditingContext alloc] init] autorelease];

    NSError *error = nil;
    Observer *user = nil;
    [ec lock];
    NS_DURING {
        user = [ec createAndInsertInstanceOfEntityNamed:@"Observer"];
        [user setUid:[[NSUUID UUID] UUIDString]];
        [ec saveChanges];

        JournalEntry *entry = [ec createAndInsertInstanceOfEntityNamed:@"JournalEntry"];
        [entry setObserver:user];
        if (![user journalEntries]) { [user setJournalEntries:[NSMutableArray array]]; }
        [[user journalEntries] addObject:entry];

        for (NSUInteger i = 0; i < kFreeTierPhotoLimit; i++) {
            Observation *withPhoto = [ec createAndInsertInstanceOfEntityNamed:@"Observation"];
            [withPhoto setJournalEntry:entry];
        if (![entry observations]) { [entry setObservations:[NSMutableArray array]]; }
        [[entry observations] addObject:withPhoto];
        [withPhoto setObserver:[entry observer]];
        if (![[entry observer] observations]) { [[entry observer] setObservations:[NSMutableArray array]]; }
        [[[entry observer] observations] addObject:withPhoto];
            [withPhoto setCaptureDate:[NSDate date]];
            [withPhoto setPhotoURLString:[NSString stringWithFormat:@"https://firebasestorage.googleapis.com/v0/b/bucket/o/journal%%2F%lu.jpg?alt=media", (unsigned long)i]];
        }

        [ec saveChanges];
    }
    NS_HANDLER {
        NSLog(@"testRemainingPhotoQuotaAtBoundaryCondition: no DB available to set up fixtures: %@", localException);
        error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    }
    NS_ENDHANDLER;
    [ec unlock];

    if (error != nil) {
        [app release];
        return;
    }

    XCTAssertEqual([user savedPhotoCountInEditingContext:ec], (NSUInteger)kFreeTierPhotoLimit);
    XCTAssertEqual([user remainingPhotoQuotaInEditingContext:ec], (NSUInteger)0);

    [app release];
}

@end
