// SPDX-License-Identifier: AGPL-3.0-or-later
//
// PresentationView.h - DTO for a published presentation.
// Copyright (C) 2026 Graham Lee

#import <Foundation/Foundation.h>

@interface PresentationView : NSObject {
    NSString *_title;
    NSString *_date;
    NSArray<NSString *> *_photos;
    NSString *_reflections;
    NSString *_mapLocation;
    BOOL _isTruncatedAndBlurred;
    BOOL _hasPrintSupport;
    NSString *_openGraphImage;
}

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *date; // Or NSDate
@property (nonatomic, copy) NSArray<NSString *> *photos;
@property (nonatomic, copy) NSString *reflections;
@property (nonatomic, copy) NSString *mapLocation;
@property (nonatomic, assign) BOOL isTruncatedAndBlurred;
@property (nonatomic, assign) BOOL hasPrintSupport;
@property (nonatomic, copy) NSString *openGraphImage;

@end
