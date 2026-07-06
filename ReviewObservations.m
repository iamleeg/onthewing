// SPDX-License-Identifier: AGPL-3.0-or-later
//
// ReviewObservations.m - Page for reviewing captured observations
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

#import <Foundation/Foundation.h>
#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#import "ReviewObservations.h"
#import "Observation.h"
#import "ObservationLocation.h"
#import "Session.h"
#import "Observer.h"
#import "JournalEntry.h"
#import "PhotoStorageMover.h"
#import "PhotoMigrator.h"
#import "OTWFirebaseStorageURL.h"
#import <EOControl/EOControl.h>
#import <EOAccess/EOAccess.h>
#import <EOAccess/EOUtilities.h>

static NSString * const kReviewObservationsErrorDomain = @"ReviewObservationsErrorDomain";
typedef NS_ENUM(NSInteger, ReviewObservationsErrorCode) {
    ReviewObservationsErrorObserverNotPersisted = 1,
    ReviewObservationsErrorSaveFailed = 2,
    ReviewObservationsErrorPhotoQuotaExceeded = 3,
};

@implementation ReviewObservations

@synthesize currentObservation = _currentObservation;
@synthesize photoStorageMover = _photoStorageMover;
@synthesize lastError = _lastError;

- (PhotoStorageMover *)photoStorageMover {
    if (_photoStorageMover == nil) {
        _photoStorageMover = [[PhotoStorageMover alloc] init];
    }
    return _photoStorageMover;
}

- (NSArray *)sortedObservations {
    Session *session = (Session *)[self session];
    NSArray *unsorted = [session unreviewedObservations];
    return [unsorted sortedArrayUsingSelector:@selector(compareChronologically:)];
}

- (BOOL)isDateToday:(NSDate *)date {
    if (!date) return NO;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger flags = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay);
    NSDateComponents *todayComponents = [calendar components:flags fromDate:[NSDate date]];
    NSDateComponents *dateComponents = [calendar components:flags fromDate:date];
    return ([todayComponents year] == [dateComponents year] &&
            [todayComponents month] == [dateComponents month] &&
            [todayComponents day] == [dateComponents day]);
}

- (NSString *)formattedCaptureDate {
    if (self.currentObservation == nil) return @"";
    NSDate *date = [self.currentObservation captureDate];
    if (!date) return @"";

    NSDateFormatter *timeFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [timeFormatter setDateFormat:@"HH:mm"];
    NSString *timeStr = [timeFormatter stringFromDate:date];

    if ([self isDateToday:date]) {
        return timeStr;
    } else {
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSString *dateStr = [dateFormatter stringFromDate:date];
        return [NSString stringWithFormat:@"%@ on %@", timeStr, dateStr];
    }
}

- (BOOL)hasCurrentBearing {
    return (self.currentObservation != nil &&
            [self.currentObservation location] != nil &&
            [[self.currentObservation location] bearing] != nil);
}

- (BOOL)hasAnyLocation {
    NSArray *obs = [self sortedObservations];
    if (obs != nil) {
        NSUInteger count = [obs count];
        for (NSUInteger i = 0; i < count; i++) {
            Observation *o = [obs objectAtIndex:i];
            ObservationLocation *loc = [o location];
            if (loc != nil && loc.latitude != nil && loc.longitude != nil) {
                return YES;
            }
        }
    }
    return NO;
}

- (id)deleteObservation {
    Session *session = (Session *)[self session];
    [session removeObservationForReview:self.currentObservation];
    if ([[session unreviewedObservations] count] == 0) {
        return [self pageWithName:@"Main"];
    }
    return self;
}

- (id)discardObservations {
    Session *session = (Session *)[self session];
    [session removeAllObservationsForReview];
    return [self pageWithName:@"Main"];
}

- (id)backToMain {
    return [self pageWithName:@"Main"];
}

- (JournalEntry *)buildJournalEntryForObservations:(NSArray *)observations
                                            observer:(Observer *)observer
                                      editingContext:(EOEditingContext *)ec {
    JournalEntry *entry = [ec createAndInsertInstanceOfEntityNamed:@"JournalEntry"];
    [observer addObject:entry toBothSidesOfRelationshipWithKey:@"journalEntries"];
    [entry setDate:[[observations objectAtIndex:0] captureDate]];
    for (Observation *observation in observations) {
        [ec insertObject:observation];
        [entry addObject:observation toBothSidesOfRelationshipWithKey:@"observations"];
    }
    return entry;
}

- (id)saveToJournal {
    Session *session = (Session *)[self session];
    EOEditingContext *ec = [session editingContext];
    NSArray *pending = [self sortedObservations];

    if ([pending count] == 0) {
        return [self pageWithName:@"Main"];
    }

    // FirebaseLogin's DB-outage fallback can leave session.user as a bare
    // Observer never inserted into any EC (see FirebaseLogin.m -login).
    // Relating such an object to a new JournalEntry and calling saveChanges
    // crashes GDL2 outright rather than throwing.
    // Give the DB another chance to persist the observer (it may
    // have only been a transient outage at login time) before giving up.
    NSError *observerError = nil;
    Observer *user = [session saveObserverWithError:&observerError];
    if (user == nil) {
        NSLog(@"Cannot save journal entry: %@", observerError);
        self.lastError = observerError ?: [NSError errorWithDomain:kReviewObservationsErrorDomain
                                                                 code:ReviewObservationsErrorObserverNotPersisted
                                                             userInfo:@{NSLocalizedDescriptionKey: @"Could not save your journal entry. Please try again."}];
        return self;
    }

    NSUInteger newPhotoCount = 0;
    for (Observation *observation in pending) {
        if ([observation photoURL] != nil) {
            newPhotoCount++;
        }
    }
    if (newPhotoCount > [user remainingPhotoQuotaInEditingContext:ec]) {
        NSError *quotaError = [NSError errorWithDomain:kReviewObservationsErrorDomain
                                                    code:ReviewObservationsErrorPhotoQuotaExceeded
                                                userInfo:@{NSLocalizedDescriptionKey:
                                                    [NSString stringWithFormat:@"You've reached the %lu-photo limit for free accounts. Upgrade your account to save more.",
                                                     (unsigned long)kFreeTierPhotoLimit]}];
        NSLog(@"Cannot save journal entry: %@", quotaError);
        self.lastError = quotaError;
        return self;
    }

    JournalEntry *entry = nil;

    [ec lock];
    NS_DURING {
        entry = [self buildJournalEntryForObservations:pending observer:user editingContext:ec];
        [ec saveChanges];
    }
    NS_HANDLER {
        NSLog(@"Failed to save journal entry: %@", localException);
        entry = nil;
    }
    NS_ENDHANDLER;
    [ec unlock];

    if (entry == nil) {
        self.lastError = [NSError errorWithDomain:kReviewObservationsErrorDomain
                                              code:ReviewObservationsErrorSaveFailed
                                          userInfo:@{NSLocalizedDescriptionKey: @"Could not save your journal entry. Please try again."}];
        return self;
    }

    NSMutableArray *migrations = [NSMutableArray array];
    for (Observation *observation in pending) {
        NSString *tempPath = [OTWFirebaseStorageURL objectPathFromDownloadURL:[observation photoURL]];
        if (tempPath == nil) {
            continue;
        }
        NSString *permanentPath = [NSString stringWithFormat:@"journal/%@/%@/%@",
                                    [user uid], [entry journalEntryId], [tempPath lastPathComponent]];
        [migrations addObject:@{
            PhotoMigratorGlobalIDKey: [ec globalIDForObject:observation],
            PhotoMigratorTempPathKey: tempPath,
            PhotoMigratorPermanentPathKey: permanentPath
        }];
    }

    [session removeAllObservationsForReview];

    PhotoMigrator *migrator = [[[PhotoMigrator alloc] initWithMover:[self photoStorageMover]] autorelease];
    for (NSDictionary *info in migrations) {
        [NSThread detachNewThreadSelector:@selector(migratePhotoWithInfo:) toTarget:migrator withObject:info];
    }

    return [self pageWithName:@"Main"];
}

- (void)dealloc {
    [_currentObservation release];
    [_photoStorageMover release];
    [_lastError release];
    [super dealloc];
}

@end
