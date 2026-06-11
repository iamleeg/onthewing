// SPDX-License-Identifier: AGPL-3.0-or-later
//
// ReviewObservations.h - Page for reviewing captured observations
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

@class Observation;

@interface ReviewObservations : GSWComponent {
    Observation *_currentObservation;
}

@property (nonatomic, retain) Observation *currentObservation;

- (NSArray *)sortedObservations;
- (id)deleteObservation;
- (id)backToMain;

- (BOOL)hasAnyLocation;
- (NSString *)formattedCaptureDate;
- (BOOL)hasCurrentBearing;

@end
