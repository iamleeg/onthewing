// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Observer.h - Observer model representation
// Copyright (C) 2026 Graham Lee
//

#import <EOControl/EOControl.h>

// Free-tier cap on saved (JournalEntry-attached) photos. No paid tier exists
// yet - this applies to everyone - but callers should go through
// -remainingPhotoQuota rather than referencing this directly, so a future
// tier distinction only has one place to change.
extern NSUInteger const kFreeTierPhotoLimit;

@interface Observer : EOCustomObject {
    NSString *_uid;
    NSString *_name;
    NSString *_email;
    NSString *_avatarUrl;
    NSString *_token;
    NSMutableArray *_journalEntries;
    NSMutableArray *_observations;
}

@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *avatarUrl;
@property (nonatomic, copy) NSString *token;

// Inverse of JournalEntry.observer.
@property (nonatomic, retain) NSMutableArray *journalEntries;

// Pending observations (inverse of Observation.observer).
@property (nonatomic, retain) NSMutableArray *observations;

- (id)initWithUid:(NSString *)uid
             name:(NSString *)name
            email:(NSString *)email
        avatarUrl:(NSString *)avatarUrl
            token:(NSString *)token;

// Count of this observer's saved (JournalEntry-attached) Observations that
// have a photo. Pending/unreviewed Observations don't count.
- (NSUInteger)savedPhotoCountInEditingContext:(EOEditingContext *)ec;

// kFreeTierPhotoLimit minus -savedPhotoCountInEditingContext:, floored at 0.
- (NSUInteger)remainingPhotoQuotaInEditingContext:(EOEditingContext *)ec;

@end

