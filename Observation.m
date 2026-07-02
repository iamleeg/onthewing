// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Observation.m - Something you see in nature.
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
// along with this program. If not, see <https://www.gnu.org/licenses/>.

#import "Observation.h"
#import "ObservationLocation.h"

@implementation Observation

@synthesize captureDate = _captureDate;
@synthesize location = _location;
@synthesize photoURL = _photoURL;

- (void)setCaptureDate:(NSDate *)captureDate {
    [self willChange];
    [_captureDate release];
    _captureDate = [captureDate retain];
}

- (void)setLocation:(ObservationLocation *)location {
    [self willChange];
    [_location release];
    _location = [location retain];
}

- (void)setPhotoURL:(NSURL *)photoURL {
    [self willChange];
    [_photoURL release];
    _photoURL = [photoURL retain];
}

- (NSComparisonResult)compareChronologically:(Observation *)other {
    if (other == nil) {
        return NSOrderedDescending;
    }
    NSDate *d1 = [self captureDate];
    NSDate *d2 = [other captureDate];
    if (d1 == nil && d2 == nil) {
        return NSOrderedSame;
    }
    if (d1 == nil) {
        return NSOrderedAscending;
    }
    if (d2 == nil) {
        return NSOrderedDescending;
    }
    return [d1 compare:d2];
}

- (void)dealloc {
    [_captureDate release];
    [_location release];
    [_photoURL release];
    [super dealloc];
}

@end
