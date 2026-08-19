// SPDX-License-Identifier: AGPL-3.0-or-later
//
// PublishedPresentation.h - EOF mapping for published presentations
// Copyright (C) 2026 Graham Lee

#import <EOControl/EOControl.h>
@class JournalEntry;

@interface PublishedPresentation : EOCustomObject {
    NSString *_urlId;
    JournalEntry *_journalEntry;
}

@property (nonatomic, copy) NSString *urlId;
@property (nonatomic, retain) JournalEntry *journalEntry;

@end
