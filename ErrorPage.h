// SPDX-License-Identifier: AGPL-3.0-or-later
//
// ErrorPage.h - Custom Error Page
// Copyright (C) 2026 Graham Lee
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

#import <WebObjects/WebObjects.h>

@interface ErrorPage : GSWComponent {
    NSString *_correlationId;
}

@property (nonatomic, retain) NSString *correlationId;

@end
