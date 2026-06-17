// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Session.m - Session class
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

#import "Session.h"
#import "Observer.h"
#import <EOControl/EOEditingContext.h>

@implementation Session

@synthesize locationPermissionState = _locationPermissionState;
@synthesize user = _user;

- (id)init {
  self = [super init];
  if (self) {
    [self setStoresIDsInCookies:YES];
    [self setStoresIDsInURLs:NO];
    _locationPermissionState = LocationPermissionUndetermined;
    _unreviewedObservations = [[NSMutableArray array] retain];
    _user = nil;
  }
  return self;
}

- (EOEditingContext *)editingContext {
  return [self defaultEditingContext];
}

- (void)addObservationForReview:(Observation *)observation {
  [_unreviewedObservations addObject: observation];
}

- (void)removeObservationForReview:(Observation *)observation {
  [_unreviewedObservations removeObject: observation];
}

- (NSArray *)unreviewedObservations {
  return [[_unreviewedObservations copy] autorelease];
}

- (void)dealloc {
  [_user release];
  [_unreviewedObservations release];
  [super dealloc];
}
@end
