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
    [_urlId release];
    _urlId = [urlId copy];
}

- (void)setJournalEntry:(JournalEntry *)journalEntry {
    [self willChange];
    [_journalEntry release];
    _journalEntry = [journalEntry retain];
}

- (void)dealloc {
    [_urlId release];
    [_journalEntry release];
    [super dealloc];
}

@end
