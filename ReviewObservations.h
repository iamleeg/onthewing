// SPDX-License-Identifier: AGPL-3.0-or-later
//
// ReviewObservations.h - Page for reviewing captured observations
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

@class Observation;
@class Observer;
@class JournalEntry;
@class EOEditingContext;
@class PhotoStorageMover;

@interface ReviewObservations : GSWComponent {
    Observation *_currentObservation;
    PhotoStorageMover *_photoStorageMover;
    NSError *_lastError;
    NSString *_title;
    NSString *_reflections;
}

@property (nonatomic, retain) Observation *currentObservation;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *reflections;

// Lazily defaults to a real PhotoStorageMover; inject a fake for tests.
@property (nonatomic, retain) PhotoStorageMover *photoStorageMover;

// Set when -saveToJournal fails (unpersistable observer, DB error, or
// over the free-tier photo quota). Not yet surfaced in the UI - once flash
// messages exist (onthewing-1yu), a consumer can read
// lastError.localizedDescription from here.
@property (nonatomic, retain) NSError *lastError;

- (NSArray *)sortedObservations;
- (id)deleteObservation;
- (id)discardObservations;
- (id)backToMain;
- (id)saveToJournal;

// Builds the in-memory JournalEntry/Observation object graph (date = earliest
// captureDate, relationships wired both ways). You need to save the
// returned object into the editing context.
- (JournalEntry *)buildJournalEntryForObservations:(NSArray *)observations
                                            observer:(Observer *)observer
                                      editingContext:(EOEditingContext *)ec;

- (BOOL)hasAnyLocation;
- (NSString *)formattedCaptureDate;
- (BOOL)hasCurrentBearing;

@end
