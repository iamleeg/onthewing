// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Capture.m - Page for capturing new observations
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

#import <Foundation/Foundation.h>
#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#import "Capture.h"

@implementation Capture

- (void)dealloc {
  [_location release];
  [_locationError release];
  [super dealloc];
}

- (void)setCapturedLocation:(ObservationLocation *)loc {
  if (_location != loc) {
    [_location release];
    _location = [loc retain];
  }
}

- (void)setLocationError:(NSString *)error {
  if (_locationError != error) {
    [_locationError release];
    _locationError = [error copy];
  }
}

- (ObservationLocation *)capturedLocation {
  return _location;
}

- (NSString *)locationError {
  return _locationError;
}

@end