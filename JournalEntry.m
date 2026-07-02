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

@implementation JournalEntry

@synthesize date = _date;
@synthesize observer = _observer;
@synthesize observations = _observations;

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

- (void)dealloc {
    [_date release];
    [_observer release];
    [_observations release];
    [super dealloc];
}

@end
