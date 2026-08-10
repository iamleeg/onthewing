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

/**
<title>BrowseJournal - A component that shows an observer their nature journal.</title>
 */


#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#include <WebObjects/WebObjects.h>

@class JournalEntry;
@class Observation;
@class PhotoStorageMover;

/**
 A component that renders the observer's nature journal.
 */
@interface BrowseJournal : GSWComponent {
    JournalEntry *_currentEntry;
    Observation *_currentObservation;
    PhotoStorageMover *_photoStorageMover;
}

/**
 The current journal entry in an iteration.

 The component binds this variable to the current journal entry from -journalEntries in a <code>WORepetition</code>.
 */
@property (nonatomic, retain) JournalEntry *currentEntry;
/**
 The current observation in an iteration of the observations in a given journal entry.

 The component binds this variables to the current observation from -currentEntryObservations in a <code>WORepetition</code>.
 */
@property (nonatomic, retain) Observation *currentObservation;

/**
 An object that manages media storage for the journal.
 */
@property (nonatomic, retain) PhotoStorageMover *photoStorageMover;

/**
 Returns the entries in the observer's journal.

 The list is organised in chronological order with the newest entry first.
 */
- (NSArray *)journalEntries;
/**
 Returns YES if the observer's journal contains one or more entries; NO otherwise.
 */
- (BOOL)hasAnyEntries;
/**
 Returns YES if the current observation has an associated photo; NO otherwise.
 */
- (BOOL)hasCurrentPhoto;
/**
 Returns YES if the current observation has a compass bearing; NO otherwise.
 */
- (BOOL)hasCurrentBearing;
/**
 Returns the list of observations in the current journal entry.
 */
- (NSArray *)currentEntryObservations;
/**
 An action that deletes the journal entry that the observer indicates.

 The action returns the observer to this component.
 */
- (id)deleteEntry;
/**
 An action that shows the observer the journal entry that they indicate.

 The action sends the observer to the <ref type="class" id="ViewJournalEntry"/> component.
 */
- (id)viewEntry;
/**
 An action that returns the observer to the <ref type="class" id="Main"/> component.
 */
- (id)backToMain;
/**
 An action that helps an observer to capture a new observation.

 The action sends the observer to the <ref type="class" id="Capture"/> component.
 */
- (id)capture;

/**
 Returns the title for a journal entry that the component shows when the observer doesn't provide a custom title.
 */
- (NSString *)defaultEntryTitle;
/**
 Returns a brief string that represents the observer's reflections on their journal entry.
 */
- (NSString *)reflectionsSnippet;
/**
 Returns YES if the current journal entry has a photo that can be displayed in its summary; NO otherwise.
 */
- (BOOL)hasSummaryPhoto;
/**
 Returns the URL to a photo that represents the current journal entry; or nil if the entry doesn't include a photo.
 */
- (NSString *)summaryPhotoURLString;

@end
