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
#import <EOControl/EOControl.h>
#import <EOAccess/EOAccess.h>
#import <EOAccess/EOUtilities.h>

@implementation BrowseJournal

@synthesize currentEntry = _currentEntry;
@synthesize currentObservation = _currentObservation;

- (NSArray *)journalEntries {
    Session *session = (Session *)[self session];
    Observer *user = [session user];
    if (user == nil || [user uid] == nil) {
        return @[];
    }

    EOEditingContext *ec = [session editingContext];
    NSArray *results = nil;
    [ec lock];
    NS_DURING {
        EOQualifier *qualifier = [EOQualifier qualifierWithQualifierFormat:@"observer.uid = %@", [user uid]];
        EOSortOrdering *sort = [EOSortOrdering sortOrderingWithKey:@"date" selector:EOCompareDescending];
        EOFetchSpecification *fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:@"JournalEntry"
                                                                                         qualifier:qualifier
                                                                                     sortOrderings:@[sort]];
        results = [ec objectsWithFetchSpecification:fetchSpec];
    }
    NS_HANDLER {
        NSLog(@"Failed to fetch journal entries: %@", localException);
        results = nil;
    }
    NS_ENDHANDLER;
    [ec unlock];

    return results ?: @[];
}

- (BOOL)hasAnyEntries {
    return [[self journalEntries] count] > 0;
}

- (NSString *)formattedEntryDate {
    return [self formattedDate:[self.currentEntry date]];
}

- (NSString *)formattedObservationDate {
    return [self formattedDate:[self.currentObservation captureDate]];
}

- (NSString *)formattedDate:(NSDate *)date {
    if (date == nil) {
        return @"";
    }
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    return [formatter stringFromDate:date];
}

- (BOOL)hasCurrentPhoto {
    return [self.currentObservation photoURL] != nil;
}

- (BOOL)hasCurrentBearing {
    return (self.currentObservation != nil &&
            [self.currentObservation location] != nil &&
            [[self.currentObservation location] bearing] != nil);
}

- (id)backToMain {
    return [self pageWithName:@"Main"];
}

- (void)dealloc {
    [_currentEntry release];
    [_currentObservation release];
    [super dealloc];
}

@end
