// SPDX-License-Identifier: AGPL-3.0-or-later
//
// PhotoCapture.m - Reusable WebObjects component for capturing/replacing photos.
// Copyright (C) 2026 Graham Lee
//

#import "PhotoCapture.h"
#import "Observation.h"

@implementation PhotoCapture

@synthesize observation = _observation;
@synthesize nextComponent = _nextComponent;
@synthesize photoURL = _photoURL;
@synthesize photoAction = _photoAction;
@synthesize imageWidth = _imageWidth;
@synthesize imageHeight = _imageHeight;

- (void)dealloc {
    [_observation release];
    [_nextComponent release];
    [_photoURL release];
    [_photoAction release];
    [_imageWidth release];
    [_imageHeight release];
    [super dealloc];
}

- (id)submitPhoto {
    if ([[self photoAction] isEqualToString:@"remove"]) {
        [[self observation] setPhotoURL:nil];
    } else if ([[self photoAction] isEqualToString:@"upload"] && [self photoURL] && [[self photoURL] length] > 0) {
        [[self observation] setPhotoURL:[NSURL URLWithString:[self photoURL]]];
    }
    
    id currentPage = [[self context] page];
    Class nextClass = NSClassFromString([self nextComponent]);
    if (currentPage && nextClass && [currentPage isKindOfClass:nextClass]) {
        return nil;
    }
    
    id page = [self pageWithName:[self nextComponent]];
    if ([page respondsToSelector:@selector(setObservation:)]) {
        [page performSelector:@selector(setObservation:) withObject:[self observation]];
    }
    return page;
}

- (NSString *)photoCaptureScriptName {
    return @"PhotoCapture.js";
}

- (NSString *)uniqueID {
    return [NSString stringWithFormat:@"%p", [self observation]];
}

- (NSString *)formID {
    return [NSString stringWithFormat:@"photo-form-%@", [self uniqueID]];
}

- (NSString *)urlInputID {
    return [NSString stringWithFormat:@"photo-url-%@", [self uniqueID]];
}

- (NSString *)actionInputID {
    return [NSString stringWithFormat:@"photo-action-%@", [self uniqueID]];
}

- (NSString *)statusID {
    return [NSString stringWithFormat:@"upload-status-%@", [self uniqueID]];
}

- (NSString *)fileInputID {
    return [NSString stringWithFormat:@"photo-file-input-%@", [self uniqueID]];
}

- (BOOL)hasPhoto {
    return [[self observation] photoURL] != nil && [[[self observation] photoURL] absoluteString].length > 0;
}

- (NSString *)labelText {
    if ([self hasPhoto]) {
        return @"Replace photo:";
    }
    return @"Add photo:";
}

- (NSString *)buttonText {
    if ([self hasPhoto]) {
        return @"Replace Photo";
    }
    return @"Upload Photo";
}

- (NSString *)removeButtonOnClick {
    return [NSString stringWithFormat:@"PhotoCapture.removePhoto('%@', '%@', '%@')", [self formID], [self urlInputID], [self actionInputID]];
}

- (NSString *)fileInputOnChange {
    return [NSString stringWithFormat:@"PhotoCapture.handleFileSelect(event, '%@', '%@', '%@', '%@', '%@')", [self uniqueID], [self formID], [self urlInputID], [self actionInputID], [self statusID]];
}

- (NSString *)uploadButtonOnClick {
    return [NSString stringWithFormat:@"document.getElementById('%@').click()", [self fileInputID]];
}

@end
