// SPDX-License-Identifier: AGPL-3.0-or-later
//
// ReviewObservations.m - Page for reviewing captured observations
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

#import "ReviewObservations.h"
#import "Observation.h"
#import "ObservationLocation.h"
#import "Session.h"

@implementation ReviewObservations

@synthesize currentObservation = _currentObservation;

- (NSArray *)sortedObservations {
    Session *session = (Session *)[self session];
    NSArray *unsorted = [session unreviewedObservations];
    return [unsorted sortedArrayUsingSelector:@selector(compareChronologically:)];
}

- (BOOL)isDateToday:(NSDate *)date {
    if (!date) return NO;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger flags = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay);
    NSDateComponents *todayComponents = [calendar components:flags fromDate:[NSDate date]];
    NSDateComponents *dateComponents = [calendar components:flags fromDate:date];
    return ([todayComponents year] == [dateComponents year] &&
            [todayComponents month] == [dateComponents month] &&
            [todayComponents day] == [dateComponents day]);
}

- (NSString *)formattedCaptureDate {
    if (self.currentObservation == nil) return @"";
    NSDate *date = [self.currentObservation captureDate];
    if (!date) return @"";

    NSDateFormatter *timeFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [timeFormatter setDateFormat:@"HH:mm"];
    NSString *timeStr = [timeFormatter stringFromDate:date];

    if ([self isDateToday:date]) {
        return timeStr;
    } else {
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSString *dateStr = [dateFormatter stringFromDate:date];
        return [NSString stringWithFormat:@"%@ on %@", timeStr, dateStr];
    }
}

- (BOOL)hasCurrentBearing {
    return (self.currentObservation != nil &&
            [self.currentObservation location] != nil &&
            [[self.currentObservation location] bearing] != nil);
}

- (BOOL)hasAnyLocation {
    NSArray *obs = [self sortedObservations];
    if (obs != nil) {
        NSUInteger count = [obs count];
        for (NSUInteger i = 0; i < count; i++) {
            Observation *o = [obs objectAtIndex:i];
            ObservationLocation *loc = [o location];
            if (loc != nil && loc.latitude != nil && loc.longitude != nil) {
                return YES;
            }
        }
    }
    return NO;
}

- (id)deleteObservation {
    Session *session = (Session *)[self session];
    [session removeObservationForReview:self.currentObservation];
    if ([[session unreviewedObservations] count] == 0) {
        return [self pageWithName:@"Main"];
    }
    return self;
}

- (id)backToMain {
    return [self pageWithName:@"Main"];
}

- (void)dealloc {
    [_currentObservation release];
    [super dealloc];
}

@end
