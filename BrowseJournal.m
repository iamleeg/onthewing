// SPDX-License-Identifier: AGPL-3.0-or-later
//
// BrowseJournal.m - Page for browsing saved journal entries.
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

#import "BrowseJournal.h"
#import "Session.h"
#import "Observer.h"
#import "JournalEntry.h"
#import "Observation.h"
#import "ObservationLocation.h"
#import "PhotoStorageMover.h"
#import "ViewJournalEntry.h"
#import "OTWFirebaseStorageURL.h"
#import <EOControl/EOControl.h>

@implementation BrowseJournal

@synthesize currentEntry = _currentEntry;
@synthesize currentObservation = _currentObservation;
@synthesize photoStorageMover = _photoStorageMover;

- (PhotoStorageMover *)photoStorageMover {
    if (_photoStorageMover == nil) {
        _photoStorageMover = [[PhotoStorageMover alloc] init];
    }
    return _photoStorageMover;
}

- (NSArray *)journalEntries {
    Session *session = (Session *)[self session];
    Observer *user = [session user];
    EOSortOrdering *sort = [EOSortOrdering sortOrderingWithKey:@"date" selector:EOCompareDescending];
    return [[user journalEntries] sortedArrayUsingKeyOrderArray:@[sort]];
}

- (BOOL)hasAnyEntries {
    return [[self journalEntries] count] > 0;
}



- (BOOL)hasCurrentPhoto {
    return [self.currentObservation photoURL] != nil;
}

- (BOOL)hasCurrentBearing {
    return [[[self currentObservation] location] bearing] != nil;
}

- (NSArray *)currentEntryObservations {
    return [self.currentEntry observations];
}

- (id)deleteEntry {
    Session *session = (Session *)[self session];
    Observer *user = [session user];
    JournalEntry *entry = self.currentEntry;

    if (entry == nil || user == nil || ![[[entry observer] uid] isEqualToString:[user uid]]) {
        return self;
    }

    EOEditingContext *ec = [session editingContext];
    PhotoStorageMover *mover = [self photoStorageMover];
    for (Observation *observation in [self currentEntryObservations]) {
        NSString *path = [OTWFirebaseStorageURL objectPathFromDownloadURL:[observation photoURL]];
        if (path == nil) {
            continue;
        }
        NSError *deleteError = nil;
        if (![mover deleteObjectAtPath:path error:&deleteError]) {
            NSLog(@"BrowseJournal: failed to delete photo at %@: %@", path, deleteError);
        }
    }

    [ec lock];
    NS_DURING {
        [ec deleteObject:entry];
        [ec saveChanges];
    }
    NS_HANDLER {
        NSLog(@"BrowseJournal: failed to delete journal entry: %@", localException);
    }
    NS_ENDHANDLER;
    [ec unlock];

    self.currentEntry = nil;
    return self;
}

- (id)viewEntry {
    ViewJournalEntry *nextPage = (ViewJournalEntry *)[self pageWithName:@"ViewJournalEntry"];
    [nextPage setCurrentEntry:self.currentEntry];
    return nextPage;
}

- (NSString *)defaultEntryTitle {
    NSDate *date = [self.currentEntry date];
    if (date) {
        NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
        [formatter setDateFormat:@"dd/MM/yyyy"];
        return [NSString stringWithFormat:@"Nature Walk on %@", [formatter stringFromDate:date]];
    }
    
    return @"Nature Walk";
}

- (NSString *)reflectionsSnippet {
    NSString *reflections = [self.currentEntry reflections];
    if (reflections && [reflections length] > 0) {
        if ([reflections length] > 100) {
            return [NSString stringWithFormat:@"%@...", [reflections substringToIndex:97]];
        }
        return reflections;
    }
    return @"";
}

- (BOOL)hasSummaryPhoto {
    return [self summaryPhotoURLString] != nil;
}

- (NSString *)summaryPhotoURLString {
    for (Observation *obs in [self currentEntryObservations]) {
        if ([obs photoURL] != nil) {
            return [obs photoURLString];
        }
    }
    return nil;
}

- (id)backToMain {
    return [self pageWithName:@"Main"];
}

- (id)capture {
    id <ObservationUsing> capturePage = (id <ObservationUsing>)[self pageWithName:@"Capture"];
    [capturePage prepareFreshObservation];
    return capturePage;
}

- (void)dealloc {
    [_currentEntry release];
    [_currentObservation release];
    [_photoStorageMover release];
    [super dealloc];
}

@end
