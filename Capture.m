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
#import "Observation.h"
#import "Session.h"

@implementation Capture

@synthesize observation = _observation;

- (void)dealloc {
  [_observation release];
  [_locationError release];
  [super dealloc];
}

- (void)setLocationError:(NSString *)error {
  if (_locationError != error) {
    [_locationError release];
    _locationError = [error copy];
  }
}

- (NSString *)locationError {
  return _locationError;
}

- (void)prepareFreshObservation {
  Observation *observation = [[[Observation alloc] init] autorelease];
  [observation setCaptureDate:[NSDate date]];
  self.observation = observation;
}

- (id)return {
  Session *session = (Session *)[self session];
  [session addObservationForReview:_observation];
  id nextPage = [self pageWithName:@"Main"];
  return nextPage;
}

@end