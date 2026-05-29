// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Compass.m - Component for displaying a compass bearing.
// Copyright (C) 2026 Graham Lee
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.

#import <Foundation/Foundation.h>
#import "Compass.h"
#import "CompassSVGGenerator.h"

@implementation Compass

- (void)dealloc {
    [_location release];
    [super dealloc];
}

- (void)setLocation:(ObservationLocation *)loc {
    if (_location != loc) {
        [_location release];
        _location = [loc retain];
    }
}

- (ObservationLocation *)location {
    return _location;
}

- (void)appendToResponse:(WOResponse *)response inContext:(WOContext *)context {
    if (_location == nil || [_location bearing] == nil) {
        return;
    }

    CompassSVGGenerator *gen = [[CompassSVGGenerator alloc] init];
    NSString *svg = [gen svgForBearing:[_location bearing]];
    [gen release];

    NSString *wrappedSvg = [NSString stringWithFormat:
        @"<div class=\"compass-container\" style=\"text-align: center; margin-top: 20px;\">%@</div>", 
        svg];
        
    [response appendContentString:wrappedSvg];
}

@end
