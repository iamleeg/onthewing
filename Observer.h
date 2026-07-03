// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Observer.h - Observer model representation
// Copyright (C) 2026 Graham Lee
//

#import <EOControl/EOControl.h>

@interface Observer : EOCustomObject {
    NSString *_uid;
    NSString *_name;
    NSString *_email;
    NSString *_avatarUrl;
    NSString *_token;
    NSMutableArray *_journalEntries;
}

@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *avatarUrl;
@property (nonatomic, copy) NSString *token;

// Inverse of JournalEntry.observer.
@property (nonatomic, retain) NSMutableArray *journalEntries;

- (id)initWithUid:(NSString *)uid
             name:(NSString *)name
            email:(NSString *)email
        avatarUrl:(NSString *)avatarUrl
            token:(NSString *)token;

@end

