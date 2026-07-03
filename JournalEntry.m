// SPDX-License-Identifier: AGPL-3.0-or-later
//
// JournalEntry.m - A saved journal entry: an Observer's dated set of Observations.
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

#import "JournalEntry.h"
#import "Observer.h"
#import <EOAccess/EOAccess.h>

@implementation JournalEntry

@synthesize journalEntryId = _journalEntryId;
@synthesize date = _date;
@synthesize observer = _observer;
@synthesize observations = _observations;

+ (NSArray *)journalEntriesForObserver:(Observer *)observer editingContext:(EOEditingContext *)ec {
    if (observer == nil || [observer uid] == nil) {
        return @[];
    }

    NSArray *results = nil;
    [ec lock];
    NS_DURING {
        EOQualifier *qualifier = [EOQualifier qualifierWithQualifierFormat:@"observer.uid = %@", [observer uid]];
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

- (void)setJournalEntryId:(NSString *)journalEntryId {
    [self willChange];
    [_journalEntryId release];
    _journalEntryId = [journalEntryId copy];
}

- (void)setDate:(NSDate *)date {
    [self willChange];
    [_date release];
    _date = [date retain];
}

- (void)setObserver:(Observer *)observer {
    [self willChange];
    [_observer release];
    _observer = [observer retain];
}

- (void)setObservations:(NSMutableArray *)observations {
    [self willChange];
    [_observations release];
    _observations = [observations retain];
}

- (void)awakeFromInsertionInEditingContext:(EOEditingContext *)editingContext {
    [super awakeFromInsertionInEditingContext:editingContext];
    if ([self journalEntryId] == nil) {
        [self setJournalEntryId:[[NSUUID UUID] UUIDString]];
    }
}

- (void)dealloc {
    [_journalEntryId release];
    [_date release];
    [_observer release];
    [_observations release];
    [super dealloc];
}

@end
