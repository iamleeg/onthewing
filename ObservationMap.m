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
#import "Observation.h"

@implementation ObservationMap

@synthesize location = _location;
@synthesize observations = _observations;

- (void)setLocation:(ObservationLocation *)loc {
    if (_location != loc) {
        [_location release];
        _location = [loc retain];
    }
    if (loc != nil) {
        Observation *obs = [[[Observation alloc] init] autorelease];
        [obs setLocation:loc];
        self.observations = [NSArray arrayWithObject:obs];
    } else {
        self.observations = nil;
    }
}

- (BOOL)hasValidCoordinates {
    if (self.observations != nil) {
        NSUInteger count = [self.observations count];
        for (NSUInteger i = 0; i < count; i++) {
            Observation *obs = [self.observations objectAtIndex:i];
            ObservationLocation *loc = [obs location];
            if (loc != nil && loc.latitude != nil && loc.longitude != nil) {
                return YES;
            }
        }
    }
    return NO;
}

- (NSString *)latitude {
    if (self.observations != nil) {
        NSUInteger count = [self.observations count];
        for (NSUInteger i = 0; i < count; i++) {
            Observation *obs = [self.observations objectAtIndex:i];
            ObservationLocation *loc = [obs location];
            if (loc != nil && loc.latitude != nil) {
                return [loc.latitude stringValue];
            }
        }
    }
    return nil;
}

- (NSString *)longitude {
    if (self.observations != nil) {
        NSUInteger count = [self.observations count];
        for (NSUInteger i = 0; i < count; i++) {
            Observation *obs = [self.observations objectAtIndex:i];
            ObservationLocation *loc = [obs location];
            if (loc != nil && loc.longitude != nil) {
                return [loc.longitude stringValue];
            }
        }
    }
    return nil;
}

- (NSString *)markersJSON {
    if (self.observations == nil || [self.observations count] == 0) {
        return nil;
    }

    NSMutableArray *markerStrings = [NSMutableArray array];
    NSDateFormatter *timeFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [timeFormatter setDateFormat:@"HH:mm"];

    NSUInteger count = [self.observations count];
    for (NSUInteger i = 0; i < count; i++) {
        Observation *obs = [self.observations objectAtIndex:i];
        ObservationLocation *loc = [obs location];
        if (loc != nil && loc.latitude != nil && loc.longitude != nil) {
            NSString *title = nil;
            if ([obs captureDate] != nil) {
                NSString *timeStr = [timeFormatter stringFromDate:[obs captureDate]];
                NSUInteger n = i + 1;
                title = [NSString stringWithFormat:@"Observation %lu at %@", n, timeStr];
            }
            
            NSString *markerStr;
            if (title != nil) {
                markerStr = [[[NSString alloc] initWithFormat:
                    @"{\"lat\":%.6f,\"lng\":%.6f,\"title\":\"%@\"}"
                    locale:nil,
                    [loc.latitude doubleValue],
                    [loc.longitude doubleValue],
                    title] autorelease];
            } else {
                markerStr = [[[NSString alloc] initWithFormat:
                    @"{\"lat\":%.6f,\"lng\":%.6f}"
                    locale:nil,
                    [loc.latitude doubleValue],
                    [loc.longitude doubleValue]] autorelease];
            }
            [markerStrings addObject:markerStr];
        }
    }

    if ([markerStrings count] == 0) {
        return nil;
    }

    NSString *json = [NSString stringWithFormat:@"[%@]", [markerStrings componentsJoinedByString:@","]];
    return [json stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
}

- (void)dealloc {
    [_location release];
    [_observations release];
    [super dealloc];
}

@end
