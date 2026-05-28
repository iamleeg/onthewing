// SPDX-License-Identifier: AGPL-3.0-or-later
//
// ObservationMap.m - Map view for observations
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

#import "ObservationMap.h"

@implementation ObservationMap

@synthesize location = _location;

- (BOOL)hasValidCoordinates {
    return (self.location != nil && 
            self.location.latitude != nil && 
            self.location.longitude != nil);
}

- (NSString *)latitude {
    return self.location.latitude ? [self.location.latitude stringValue] : nil;
}

- (NSString *)longitude {
    return self.location.longitude ? [self.location.longitude stringValue] : nil;
}

@end
