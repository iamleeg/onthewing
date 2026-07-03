// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Observation.h - Something you see in nature.
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

#import <EOControl/EOControl.h>

@class ObservationLocation;
@class JournalEntry;

@interface Observation : EOCustomObject
{
    NSString *_observationId;
    NSDate *_captureDate;
    ObservationLocation *_location;
    NSURL *_photoURL;
    JournalEntry *_journalEntry;
}

@property (nonatomic, copy) NSString *observationId;

@property (nonatomic, strong) NSDate *captureDate;
@property (nonatomic, strong) ObservationLocation *location;
@property (nonatomic, retain) NSURL *photoURL;

// The JournalEntry this Observation belongs to, once saved (nil for pending,
// unreviewed Observations - see Session.h). Inverse of JournalEntry.observations.
@property (nonatomic, retain) JournalEntry *journalEntry;

// EOF persistence plumbing: photoURL/location aren't natively storable value
// classes for GDL2's Postgres adaptor (no NSURL support, and location's 4
// numeric fields are embedded as flat columns rather than a separate entity -
// see the epic's design). These pass-through properties are what OTWApp.m's
// schema actually maps to columns; they proxy through the properties above
// (and their existing willChange-calling setters) rather than duplicating
// storage. Not intended for direct use outside EOF/tests - use photoURL and
// location instead.
@property (nonatomic, copy) NSString *photoURLString;
@property (nonatomic, retain) NSNumber *latitude;
@property (nonatomic, retain) NSNumber *longitude;
@property (nonatomic, retain) NSNumber *accuracy;
@property (nonatomic, retain) NSNumber *bearing;

- (NSComparisonResult)compareChronologically:(Observation *)other;

@end

@protocol ObservationUsing <NSObject>
- (void)setObservation:(Observation *)loc;

// Creates a new Observation dated now and assigns it via -setObservation:.
- (void)prepareFreshObservation;
@end
