// SPDX-License-Identifier: AGPL-3.0-or-later
//
// PresentationService.h - Service handling presentation lifecycle
// Copyright (C) 2026 Graham Lee

#import <Foundation/Foundation.h>

@class PresentationView;
@class EOEditingContext;

@interface PresentationService : NSObject {
    EOEditingContext *_editingContext;
}

@property (nonatomic, retain) EOEditingContext *editingContext;

- (instancetype)initWithEditingContext:(EOEditingContext *)ec;

- (NSString *)publishPresentationForEntryId:(NSString *)entryId observerId:(NSString *)observerId;
- (PresentationView *)previewPresentationForEntryId:(NSString *)entryId observerId:(NSString *)observerId;
- (PresentationView *)getPresentationForUrlId:(NSString *)urlId;
- (void)unpublishPresentationForEntryId:(NSString *)entryId;
- (void)handleJournalEntryUpdate:(NSString *)entryId;

@end
