// SPDX-License-Identifier: AGPL-3.0-or-later
//
// PresentationView.m - DTO for a published presentation.
// Copyright (C) 2026 Graham Lee

#import "PresentationView.h"

@implementation PresentationView

@synthesize title = _title;
@synthesize date = _date;
@synthesize photos = _photos;
@synthesize reflections = _reflections;
@synthesize mapLocation = _mapLocation;
@synthesize isTruncatedAndBlurred = _isTruncatedAndBlurred;
@synthesize hasPrintSupport = _hasPrintSupport;
@synthesize openGraphImage = _openGraphImage;

- (void)dealloc {
    [_title release];
    [_date release];
    [_photos release];
    [_reflections release];
    [_mapLocation release];
    [_openGraphImage release];
    [super dealloc];
}

@end
