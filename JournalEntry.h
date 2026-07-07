// SPDX-License-Identifier: AGPL-3.0-or-later
//
// JournalEntry.h - A saved journal entry: an Observer's dated set of Observations.
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

#import <EOControl/EOControl.h>

@class Observer;

@interface JournalEntry : EOCustomObject
{
    NSString *_journalEntryId;
    Observer *_observer;
    NSMutableArray *_observations;
    NSString *_title;
    NSString *_reflections;
}

@property (nonatomic, copy) NSString *journalEntryId;

@property (nonatomic, readonly) NSDate *date;
@property (nonatomic, retain) Observer *observer;
@property (nonatomic, retain) NSMutableArray *observations;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *reflections;

@end
