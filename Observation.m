// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Observation.m - Something you see in nature.
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

#import "Observation.h"
#import "ObservationLocation.h"
#import "JournalEntry.h"
#import <EOAccess/EOAccess.h>

@implementation Observation

@synthesize observationId = _observationId;
@synthesize captureDate = _captureDate;
@synthesize location = _location;
@synthesize photoURL = _photoURL;
@synthesize journalEntry = _journalEntry;

- (void)setObservationId:(NSString *)observationId {
    [self willChange];
    [_observationId release];
    _observationId = [observationId copy];
}

- (void)setCaptureDate:(NSDate *)captureDate {
    [self willChange];
    [_captureDate release];
    _captureDate = [captureDate retain];
}

- (void)setLocation:(ObservationLocation *)location {
    [self willChange];
    [_location release];
    _location = [location retain];
}

- (void)setPhotoURL:(NSURL *)photoURL {
    [self willChange];
    [_photoURL release];
    _photoURL = [photoURL retain];
}

- (void)setJournalEntry:(JournalEntry *)journalEntry {
    [self willChange];
    [_journalEntry release];
    _journalEntry = [journalEntry retain];
}

- (NSString *)photoURLString {
    return [[self photoURL] absoluteString];
}

- (void)setPhotoURLString:(NSString *)photoURLString {
    [self setPhotoURL:(photoURLString ? [NSURL URLWithString:photoURLString] : nil)];
}

- (NSNumber *)latitude {
    return [[self location] latitude];
}

- (void)setLatitude:(NSNumber *)latitude {
    if ([self location] == nil) {
        [self setLocation:[[[ObservationLocation alloc] init] autorelease]];
    }
    [[self location] setLatitude:latitude];
}

- (NSNumber *)longitude {
    return [[self location] longitude];
}

- (void)setLongitude:(NSNumber *)longitude {
    if ([self location] == nil) {
        [self setLocation:[[[ObservationLocation alloc] init] autorelease]];
    }
    [[self location] setLongitude:longitude];
}

- (NSNumber *)accuracy {
    return [[self location] accuracy];
}

- (void)setAccuracy:(NSNumber *)accuracy {
    if ([self location] == nil) {
        [self setLocation:[[[ObservationLocation alloc] init] autorelease]];
    }
    [[self location] setAccuracy:accuracy];
}

- (NSNumber *)bearing {
    return [[self location] bearing];
}

- (void)setBearing:(NSNumber *)bearing {
    if ([self location] == nil) {
        [self setLocation:[[[ObservationLocation alloc] init] autorelease]];
    }
    [[self location] setBearing:bearing];
}

- (void)awakeFromInsertionInEditingContext:(EOEditingContext *)editingContext {
    [super awakeFromInsertionInEditingContext:editingContext];
    if ([self observationId] == nil) {
        [self setObservationId:[[NSUUID UUID] UUIDString]];
    }
}

- (NSComparisonResult)compareChronologically:(Observation *)other {
    if (other == nil) {
        return NSOrderedDescending;
    }
    NSDate *d1 = [self captureDate];
    NSDate *d2 = [other captureDate];
    if (d1 == nil && d2 == nil) {
        return NSOrderedSame;
    }
    if (d1 == nil) {
        return NSOrderedAscending;
    }
    if (d2 == nil) {
        return NSOrderedDescending;
    }
    return [d1 compare:d2];
}

+ (NSArray *)observationsForJournalEntry:(JournalEntry *)entry editingContext:(EOEditingContext *)ec {
    if (entry == nil) {
        return @[];
    }

    NSArray *results = nil;
    [ec lock];
    NS_DURING {
        EOQualifier *qualifier = [EOQualifier qualifierWithQualifierFormat:@"journalEntry.journalEntryId = %@", [entry journalEntryId]];
        EOFetchSpecification *fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:@"Observation"
                                                                                         qualifier:qualifier
                                                                                     sortOrderings:nil];
        results = [ec objectsWithFetchSpecification:fetchSpec];
    }
    NS_HANDLER {
        NSLog(@"Failed to fetch observations for entry: %@", localException);
        results = nil;
    }
    NS_ENDHANDLER;
    [ec unlock];
    return results ?: @[];
}

- (void)dealloc {
    [_observationId release];
    [_captureDate release];
    [_location release];
    [_photoURL release];
    [_journalEntry release];
    [super dealloc];
}

@end
