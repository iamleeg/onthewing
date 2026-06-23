// SPDX-License-Identifier: AGPL-3.0-or-later
//
// LocationCapture.m - Dynamic component for capturing location and bearing.
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

#import "LocationCapture.h"
#import "Observation.h"
#import "ObservationLocation.h"
#import "Session.h"

@implementation LocationCapture

@synthesize latitude;
@synthesize longitude;
@synthesize accuracy;
@synthesize bearing;
@synthesize locationError;
@synthesize bearingError;
@synthesize nextComponent;
@synthesize observation = _observation;

- (void)dealloc {
    [latitude release];
    [longitude release];
    [accuracy release];
    [bearing release];
    [locationError release];
    [bearingError release];
    [nextComponent release];
    [_observation release];
    [super dealloc];
}

- (id)recordLocationAndBearing {
    Session *session = (Session *)[self session];
    if ([[self locationError] isEqualToString:@"1"]) {
        [session setLocationPermissionState:LocationPermissionDenied];
    } else if ([self latitude] || [[self locationError] isEqualToString:@"2"] || [[self locationError] isEqualToString:@"3"]) {
        [session setLocationPermissionState:LocationPermissionAllowed];
    }

    ObservationLocation *loc = nil;
    if ([self latitude] || [self longitude] || [self bearing]) {
        loc = [[[ObservationLocation alloc] init] autorelease];
        if ([self latitude]) {
            [loc setLatitude:[NSNumber numberWithDouble:[[self latitude] doubleValue]]];
        }
        if ([self longitude]) {
            [loc setLongitude:[NSNumber numberWithDouble:[[self longitude] doubleValue]]];
        }
        if ([self accuracy]) {
            [loc setAccuracy:[NSNumber numberWithDouble:[[self accuracy] doubleValue]]];
        }
        if ([self bearing] && [[self bearing] length] > 0) {
            [loc setBearing:[NSNumber numberWithDouble:[[self bearing] doubleValue]]];
        }
    }
    [_observation setLocation: loc];
    
    id currentPage = [[self context] page];
    Class nextClass = NSClassFromString([self nextComponent]);
    if (currentPage && nextClass && [currentPage isKindOfClass:nextClass]) {
        if (loc == nil) {
            if ([currentPage respondsToSelector:@selector(setLocationError:)]) {
                [currentPage performSelector:@selector(setLocationError:) withObject:@"No location data was captured."];
            }
        }
        return nil;
    }
    
    id <LocationUsing> page = (id <LocationUsing>)[self pageWithName:[self nextComponent]];
    [page setObservation:_observation];
    if (loc == nil) {
        [page setLocationError:@"No location data was captured."];
    }
    return page;
}

- (NSString *)deviceCaptureScriptName {
    return @"DeviceCapture.js";
}

@end
