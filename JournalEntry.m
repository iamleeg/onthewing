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
@synthesize observer = _observer;
@synthesize observations = _observations;
@synthesize title = _title;
@synthesize reflections = _reflections;

- (void)setJournalEntryId:(NSString *)journalEntryId {
    [self willChange];
    [_journalEntryId release];
    _journalEntryId = [journalEntryId copy];
}


- (NSDate *)date {
    return [[[[self observations] sortedArrayUsingSelector:@selector(compareChronologically:)] firstObject] captureDate];
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

- (void)setTitle:(NSString *)title {
    [self willChange];
    [_title release];
    _title = [title copy];
}

- (void)setReflections:(NSString *)reflections {
    [self willChange];
    [_reflections release];
    _reflections = [reflections copy];
}

- (void)awakeFromInsertionInEditingContext:(EOEditingContext *)editingContext {
    [super awakeFromInsertionInEditingContext:editingContext];
    if ([self journalEntryId] == nil) {
        [self setJournalEntryId:[[NSUUID UUID] UUIDString]];
    }
}

- (NSException *)validateForSave {
    NSException *exception = [super validateForSave];
    if (exception != nil) {
        return exception;
    }
    
    NSArray *obs = [self observations];
    if (obs == nil || [obs count] == 0) {
        return [NSException exceptionWithName:@"EOValidationException"
                                       reason:@"A JournalEntry must have at least one observation."
                                     userInfo:nil];
    }
    
    return nil;
}

- (void)dealloc {
    [_journalEntryId release];
    [_observer release];
    [_observations release];
    [_title release];
    [_reflections release];
    [super dealloc];
}

@end
