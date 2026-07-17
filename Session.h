// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Session.h - Session class
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

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#include <WebObjects/WebObjects.h>

#import "LocationPermission.h"

@class Observation;
@class Observer;
@class EOEditingContext;

@interface Session : WOSession {
    LocationPermissionState _locationPermissionState;
    NSMutableArray *_unreviewedObservations;
    Observer *_user;
}

@property (nonatomic, assign) LocationPermissionState locationPermissionState;
@property (nonatomic, readonly) NSArray *unreviewedObservations;
@property (nonatomic, retain) Observer *user;
@property (nonatomic, readonly) EOEditingContext *editingContext;

- (NSDictionary *)stateDictionary;
- (void)restoreFromStateDictionary:(NSDictionary *)dict;

- (void)addObservationForReview:(Observation *)observation;
- (void)removeObservationForReview:(Observation *)observation;
- (void)removeAllObservationsForReview;

// If user is already registered in editingContext, returns it unchanged.
// Otherwise (e.g. FirebaseLogin's DB-outage fallback left a bare, unpersisted
// Observer), retries fetch-or-create against the DB, replacing self.user with
// the saved object and returning it on success. Returns nil and sets
// *error on failure - self.user is left unchanged (still unpersisted) in
// that case.
- (Observer *)saveObserverWithError:(NSError **)error;

@end
