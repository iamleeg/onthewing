// SPDX-License-Identifier: AGPL-3.0-or-later
//
// BrowseJournal.h - Page for browsing saved journal entries.
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

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#include <WebObjects/WebObjects.h>

@class JournalEntry;
@class Observation;
@class PhotoStorageMover;

@interface BrowseJournal : GSWComponent {
    JournalEntry *_currentEntry;
    Observation *_currentObservation;
    PhotoStorageMover *_photoStorageMover;
}

@property (nonatomic, retain) JournalEntry *currentEntry;
@property (nonatomic, retain) Observation *currentObservation;

// Lazily defaults to a real PhotoStorageMover; inject a fake for tests.
@property (nonatomic, retain) PhotoStorageMover *photoStorageMover;

/// A list of journal entries.
/// The list is restricted to this user's entries, in reverse chronological order.
- (NSArray *)journalEntries;
- (BOOL)hasAnyEntries;

// Observations belonging to currentEntry. Uses Observation
// +observationsForJournalEntry:editingContext: rather than binding
// currentEntry.observations directly in the .wod - that relationship
// doesn't fault correctly in GDL2.
- (NSArray *)currentEntryObservations;

// Deletes the current entry.
- (id)deleteEntry;

- (id)backToMain;
- (id)capture;

@end
