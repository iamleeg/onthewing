// SPDX-License-Identifier: AGPL-3.0-or-later
//
// ViewJournalEntry.m - Page for viewing and editing a single journal entry.
// Copyright (C) 2026 Graham Lee

#import "ViewJournalEntry.h"
#import "Session.h"
#import "JournalEntry.h"
#import "Observation.h"
#import "ObservationLocation.h"
#import "PhotoStorageMover.h"
#import "OTWFirebaseStorageURL.h"
#import "PresentationService.h"
#import <EOControl/EOControl.h>

@implementation ViewJournalEntry

@synthesize currentEntry = _currentEntry;
@synthesize currentObservation = _currentObservation;
@synthesize editedTitle = _editedTitle;
@synthesize editedReflections = _editedReflections;
@synthesize lastError = _lastError;
@synthesize photoStorageMover = _photoStorageMover;

- (PhotoStorageMover *)photoStorageMover {
    if (_photoStorageMover == nil) {
        _photoStorageMover = [[PhotoStorageMover alloc] init];
    }
    return _photoStorageMover;
}

- (void)setCurrentEntry:(JournalEntry *)entry {
    [self willChange];
    [_currentEntry release];
    _currentEntry = [entry retain];
    self.editedTitle = [entry title];
    self.editedReflections = [entry reflections];
}

- (NSArray *)observations {
    return [self.currentEntry observations];
}

- (BOOL)hasLocations {
    NSArray *obs = [self observations];
    if (obs != nil) {
        for (Observation *o in obs) {
            ObservationLocation *loc = [o location];
            if (loc != nil && loc.latitude != nil && loc.longitude != nil) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)hasCurrentBearing {
    return [[[self currentObservation] location] bearing] != nil;
}


- (id)saveChanges {
    [self.currentEntry setTitle:self.editedTitle];
    [self.currentEntry setReflections:self.editedReflections];
    
    EOEditingContext *ec = [[self session] editingContext];
    [ec lock];
    NS_DURING {
        PresentationService *ps = [[[PresentationService alloc] initWithEditingContext:ec] autorelease];
        [ps handleJournalEntryUpdate:[self.currentEntry journalEntryId]];
        [ec saveChanges];
        self.lastError = nil;
    }
    NS_HANDLER {
        NSLog(@"Failed to save journal entry changes: %@", localException);
        self.lastError = [NSError errorWithDomain:@"ViewJournalEntry" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Could not save changes."}];
    }
    NS_ENDHANDLER;
    [ec unlock];
    
    return self;
}

- (id)deleteEntry {
    Session *session = (Session *)[self session];
    EOEditingContext *ec = [session editingContext];
    PhotoStorageMover *mover = [self photoStorageMover];
    
    for (Observation *observation in [self observations]) {
        NSString *path = [OTWFirebaseStorageURL objectPathFromDownloadURL:[observation photoURL]];
        if (path == nil) continue;
        NSError *deleteError = nil;
        if (![mover deleteObjectAtPath:path error:&deleteError]) {
            NSLog(@"ViewJournalEntry: failed to delete photo at %@: %@", path, deleteError);
        }
    }

    [ec lock];
    NS_DURING {
        [ec deleteObject:self.currentEntry];
        [ec saveChanges];
    }
    NS_HANDLER {
        NSLog(@"ViewJournalEntry: failed to delete journal entry: %@", localException);
    }
    NS_ENDHANDLER;
    [ec unlock];

    self.currentEntry = nil;
    return [self pageWithName:@"BrowseJournal"];
}

- (id)backToJournal {
    return [self pageWithName:@"BrowseJournal"];
}

- (void)dealloc {
    [_currentEntry release];
    [_currentObservation release];
    [_editedTitle release];
    [_editedReflections release];
    [_lastError release];
    [_photoStorageMover release];
    [super dealloc];
}

@end
