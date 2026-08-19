// SPDX-License-Identifier: AGPL-3.0-or-later
//
// PresentationService.m
// Copyright (C) 2026 Graham Lee

#import "PresentationService.h"
#import "PresentationView.h"
#import "PublishedPresentation.h"
#import "Observer.h"
#import "JournalEntry.h"
#import "Observation.h"
#import <EOControl/EOControl.h>
#import <EOAccess/EOAccess.h>

@implementation PresentationService

@synthesize editingContext = _editingContext;

- (instancetype)initWithEditingContext:(EOEditingContext *)ec {
    self = [super init];
    if (self) {
        _editingContext = [ec retain];
    }
    return self;
}

- (void)dealloc {
    [_editingContext release];
    [super dealloc];
}

- (NSString *)publishPresentationForEntryId:(NSString *)entryId observerId:(NSString *)observerId {
    // Check if premium
    EOFetchSpecification *obsFetch = [EOFetchSpecification fetchSpecificationWithEntityName:@"Observer"
                                                                                  qualifier:[EOQualifier qualifierWithQualifierFormat:@"uid = %@", observerId]
                                                                              sortOrderings:nil];
    Observer *obs = [[self.editingContext objectsWithFetchSpecification:obsFetch] lastObject];
    NSLog(@"obs.uid = %@, obs.isPremium = %@, boolValue = %d", obs.uid, obs.isPremium, [obs.isPremium boolValue]); if (!obs || ![obs.isPremium boolValue]) {
        return nil;
    }
    
    // Check if journal entry exists and belongs to observer
    EOFetchSpecification *entryFetch = [EOFetchSpecification fetchSpecificationWithEntityName:@"JournalEntry"
                                                                                    qualifier:[EOQualifier qualifierWithQualifierFormat:@"journalEntryId = %@", entryId]
                                                                                sortOrderings:nil];
    JournalEntry *entry = [[self.editingContext objectsWithFetchSpecification:entryFetch] lastObject];
    NSLog(@"entry: %@, entry.observer: %@, obs: %@", entry, entry.observer, obs); NSLog(@"entry = %@, entry.observer.uid = %@, obs.uid = %@", entry, [entry.observer uid], [obs uid]); if (!entry || ![[entry.observer uid] isEqualToString:[obs uid]]) {
        return nil;
    }
    
    // Check if already published
    EOFetchSpecification *pubFetch = [EOFetchSpecification fetchSpecificationWithEntityName:@"PublishedPresentation"
                                                                                  qualifier:[EOQualifier qualifierWithQualifierFormat:@"journalEntry = %@", entry]
                                                                              sortOrderings:nil];
    PublishedPresentation *existing = [[self.editingContext objectsWithFetchSpecification:pubFetch] lastObject];
    if (existing) {
        return [existing urlId];
    }
    
    // Generate UUID for URL
    NSString *urlId = [[NSUUID UUID] UUIDString];
    
    PublishedPresentation *pub = [self.editingContext createAndInsertInstanceOfEntityNamed:@"PublishedPresentation"];
    [pub setUrlId:urlId];
    [pub setJournalEntry:entry];
    
    [self.editingContext saveChanges];
    return urlId;
}

- (PresentationView *)_buildViewForEntry:(JournalEntry *)entry truncateAndBlur:(BOOL)truncate {
    PresentationView *view = [[[PresentationView alloc] init] autorelease];
    [view setTitle:entry.title];
    [view setDate:[[entry date] description]];
    
    if (truncate) {
        if ([entry.reflections length] > 100) {
            [view setReflections:[NSString stringWithFormat:@"%@...", [entry.reflections substringToIndex:100]]];
        } else {
            [view setReflections:entry.reflections];
        }
    } else {
        [view setReflections:entry.reflections];
    }
    
    NSMutableArray *photos = [NSMutableArray array];
    for (Observation *obs in entry.observations) {
        if ([obs photoURLString]) {
            [photos addObject:[obs photoURLString]];
        }
    }
    [view setPhotos:photos];
    
    if (photos.count > 0) {
        [view setOpenGraphImage:[photos firstObject]];
    }
    
    [view setIsTruncatedAndBlurred:truncate];
    [view setHasPrintSupport:!truncate];
    return view;
}

- (PresentationView *)previewPresentationForEntryId:(NSString *)entryId observerId:(NSString *)observerId {
    EOFetchSpecification *entryFetch = [EOFetchSpecification fetchSpecificationWithEntityName:@"JournalEntry"
                                                                                    qualifier:[EOQualifier qualifierWithQualifierFormat:@"journalEntryId = %@ AND observer.uid = %@", entryId, observerId]
                                                                                sortOrderings:nil];
    JournalEntry *entry = [[self.editingContext objectsWithFetchSpecification:entryFetch] lastObject];
    if (!entry) return nil;
    
    return [self _buildViewForEntry:entry truncateAndBlur:YES];
}

- (PresentationView *)getPresentationForUrlId:(NSString *)urlId {
    EOFetchSpecification *fetch = [EOFetchSpecification fetchSpecificationWithEntityName:@"PublishedPresentation"
                                                                               qualifier:[EOQualifier qualifierWithQualifierFormat:@"urlId = %@", urlId]
                                                                           sortOrderings:nil];
    PublishedPresentation *pub = [[self.editingContext objectsWithFetchSpecification:fetch] lastObject];
    if (!pub) return nil;
    
    return [self _buildViewForEntry:pub.journalEntry truncateAndBlur:NO];
}

- (void)unpublishPresentationForEntryId:(NSString *)entryId {
    EOFetchSpecification *fetch = [EOFetchSpecification fetchSpecificationWithEntityName:@"PublishedPresentation"
                                                                               qualifier:[EOQualifier qualifierWithQualifierFormat:@"journalEntry.journalEntryId = %@", entryId]
                                                                           sortOrderings:nil];
    NSArray *pubs = [self.editingContext objectsWithFetchSpecification:fetch];
    for (PublishedPresentation *pub in pubs) {
        [self.editingContext deleteObject:pub];
    }
    [self.editingContext saveChanges];
}

- (void)handleJournalEntryUpdate:(NSString *)entryId {
    [self unpublishPresentationForEntryId:entryId];
}

@end
