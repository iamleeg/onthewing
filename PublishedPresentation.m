// SPDX-License-Identifier: AGPL-3.0-or-later
//
// PublishedPresentation.m
// Copyright (C) 2026 Graham Lee

#import "PublishedPresentation.h"
#import "JournalEntry.h"

@implementation PublishedPresentation

@synthesize urlId = _urlId;
@synthesize journalEntry = _journalEntry;

- (void)setUrlId:(NSString *)urlId {
    [self willChange];
    id new_urlId = [urlId copy];
    [_urlId autorelease];
    _urlId = new_urlId;
}

- (void)setJournalEntry:(JournalEntry *)journalEntry {
    [self willChange];
    [journalEntry retain];
    [_journalEntry autorelease];
    _journalEntry = journalEntry;
}

- (void)dealloc {
    [_urlId release];
    [_journalEntry release];
    [super dealloc];
}

@end
