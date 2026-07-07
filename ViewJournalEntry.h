// SPDX-License-Identifier: AGPL-3.0-or-later
//
// ViewJournalEntry.h - Page for viewing and editing a single journal entry.
// Copyright (C) 2026 Graham Lee

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#include <WebObjects/WebObjects.h>

@class JournalEntry;
@class Observation;
@class PhotoStorageMover;

@interface ViewJournalEntry : GSWComponent {
    JournalEntry *_currentEntry;
    Observation *_currentObservation;
    NSString *_editedTitle;
    NSString *_editedReflections;
    NSError *_lastError;
    PhotoStorageMover *_photoStorageMover;
}

@property (nonatomic, retain) JournalEntry *currentEntry;
@property (nonatomic, retain) Observation *currentObservation;
@property (nonatomic, copy) NSString *editedTitle;
@property (nonatomic, copy) NSString *editedReflections;
@property (nonatomic, retain) NSError *lastError;
@property (nonatomic, retain) PhotoStorageMover *photoStorageMover;

- (NSArray *)observations;
- (id)saveChanges;
- (id)deleteEntry;
- (id)backToJournal;
- (BOOL)hasLocations;
- (BOOL)hasCurrentBearing;

@end
