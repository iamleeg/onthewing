// SPDX-License-Identifier: AGPL-3.0-or-later
//
// PhotoCapture.h - Reusable WebObjects component for capturing/replacing photos.
// Copyright (C) 2026 Graham Lee
//

#import <WebObjects/WebObjects.h>

@class Observation;

@interface PhotoCapture : GSWComponent {
    Observation *_observation;
    NSString *_nextComponent;
    NSString *_photoURL;
    NSString *_photoAction;
    NSString *_imageWidth;
    NSString *_imageHeight;
}

@property (nonatomic, strong) Observation *observation;
@property (nonatomic, copy) NSString *nextComponent;
@property (nonatomic, copy) NSString *photoURL;
@property (nonatomic, copy) NSString *photoAction;
@property (nonatomic, copy) NSString *imageWidth;
@property (nonatomic, copy) NSString *imageHeight;

- (id)submitPhoto;
- (NSString *)photoCaptureScriptName;
- (NSString *)uniqueID;
- (NSString *)formID;
- (NSString *)urlInputID;
- (NSString *)actionInputID;
- (NSString *)statusID;
- (NSString *)fileInputID;
- (BOOL)hasPhoto;
- (NSString *)labelText;
- (NSString *)buttonText;
- (NSString *)removeButtonOnClick;
- (NSString *)fileInputOnChange;
- (NSString *)uploadButtonOnClick;

@end
