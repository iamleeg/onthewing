// SPDX-License-Identifier: AGPL-3.0-or-later
//
// ErrorPage.m - Custom Error Page
// Copyright (C) 2026 Graham Lee
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

#import "ErrorPage.h"

@implementation ErrorPage

@synthesize correlationId = _correlationId;

- (void)dealloc {
    [_correlationId release];
    [super dealloc];
}

@end
