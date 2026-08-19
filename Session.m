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
#import "Observation.h"
#import "OTWFlashMessage.h"
#import <EOControl/EOControl.h>
#import <EOAccess/EOAccess.h>
#import <EOAccess/EOUtilities.h>

static NSString * const kSessionErrorDomain = @"SessionErrorDomain";

typedef NS_ENUM(NSInteger, SessionErrorCode) {
  SessionErrorNoUser = 1,
  SessionErrorPersistenceFailed = 2
};

@implementation Session

@synthesize locationPermissionState = _locationPermissionState;
@synthesize flashMessage = _flashMessage;

- (id)init {
  self = [super init];
  if (self) {
    [self setStoresIDsInCookies:YES];
    [self setStoresIDsInURLs:NO];
    _locationPermissionState = LocationPermissionUndetermined;
    _unreviewedObservations = [[NSMutableArray array] retain];
    _user = nil;
    _flashMessage = nil;
  }
  return self;
}

- (EOEditingContext *)editingContext {
  return [self defaultEditingContext];
}

- (void)_tryPersistPendingObservation:(Observation *)observation {
    NSError *error = nil;
    Observer *persistedUser = [self saveObserverWithError:&error];
    if (persistedUser) {
        EOEditingContext *ec = [self editingContext];
        if ([observation editingContext] == nil) {
            if (!observation.observationId) {
                observation.observationId = [[NSUUID UUID] UUIDString];
            }
            [ec insertObject:observation];
        }
        [observation setObserver:persistedUser];
        NS_DURING {
            [ec saveChanges];
        } NS_HANDLER {
            NSLog(@"Failed to save pending observation: %@", localException);
        } NS_ENDHANDLER;
    }
}

- (void)addObservationForReview:(Observation *)observation {
  if (![_unreviewedObservations containsObject:observation]) {
      [_unreviewedObservations addObject: observation];
  }
  [self _tryPersistPendingObservation:observation];
}

- (void)removeObservationForReview:(Observation *)observation {
  [_unreviewedObservations removeObject: observation];
  if ([observation editingContext] != nil && observation.journalEntry == nil) {
      EOEditingContext *ec = [observation editingContext];
      [ec deleteObject:observation];
      NS_DURING {
          [ec saveChanges];
      } NS_HANDLER {
          NSLog(@"Failed to delete pending observation: %@", localException);
      } NS_ENDHANDLER;
  }
}

- (OTWFlashMessage *)consumeFlashMessage {
  OTWFlashMessage *msg = [[_flashMessage retain] autorelease];
  self.flashMessage = nil;
  return msg;
}

- (void)removeAllObservationsForReview {
    EOEditingContext *ec = [self editingContext];
    BOOL deletedAny = NO;
    for (Observation *obs in _unreviewedObservations) {
        if ([obs editingContext] != nil && obs.journalEntry == nil) {
            [ec deleteObject:obs];
            deletedAny = YES;
        }
    }
    [_unreviewedObservations removeAllObjects];
    if (deletedAny) {
        NS_DURING {
            [ec saveChanges];
        } NS_HANDLER {
            NSLog(@"Failed to delete all pending observations: %@", localException);
        } NS_ENDHANDLER;
    }
}

- (Observer *)saveObserverWithError:(NSError **)error {
  if (_user == nil) {
    if (error) {
      *error = [NSError errorWithDomain:kSessionErrorDomain
                                    code:SessionErrorNoUser
                                userInfo:@{ NSLocalizedDescriptionKey: @"No user is signed in" }];
    }
    return nil;
  }

  EOEditingContext *ec = [self editingContext];
  if ([ec globalIDForObject:_user] != nil) {
    return _user;
  }

  Observer *persisted = nil;
  NSError *persistError = nil;
  [ec lock];
  NS_DURING {
    EOQualifier *qualifier = [EOQualifier qualifierWithQualifierFormat:@"uid = %@", [_user uid]];
    EOFetchSpecification *fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:@"Observer"
                                                                                     qualifier:qualifier
                                                                                 sortOrderings:nil];
    NSArray *results = [ec objectsWithFetchSpecification:fetchSpec];
    if ([results count] > 0) {
      persisted = [results objectAtIndex:0];
    } else {
      persisted = [ec createAndInsertInstanceOfEntityNamed:@"Observer"];
      [persisted setUid:[_user uid]];
      [persisted setName:[_user name]];
      [persisted setEmail:[_user email]];
      [persisted setAvatarUrl:[_user avatarUrl]];
      [persisted setToken:[_user token]];
      [ec saveChanges];
    }
  }
  NS_HANDLER {
    NSLog(@"Failed to persist observer: %@", localException);
    persistError = [NSError errorWithDomain:kSessionErrorDomain
                                        code:SessionErrorPersistenceFailed
                                    userInfo:@{ NSLocalizedDescriptionKey: [localException reason] ?: @"Failed to persist observer" }];
    persisted = nil;
  }
  NS_ENDHANDLER;
  [ec unlock];

  if (persisted == nil) {
    if (error) {
      *error = persistError;
    }
    return nil;
  }

  [self setUser:persisted];
  return persisted;
}

- (Observer *)user {
    return [[_user retain] autorelease];
}

- (void)setUser:(Observer *)user {
    [user retain];
    [_user autorelease];
    _user = user;
    if (_user && [_user uid]) {
        [self _loadPendingObservations];
    }
}

- (void)_loadPendingObservations {
    EOEditingContext *ec = [self editingContext];
    if ([ec globalIDForObject:_user] == nil) return;

    NSDate *cutoffDate = [NSDate dateWithTimeIntervalSinceNow:-86400];
    
    EOQualifier *qual = [EOQualifier qualifierWithQualifierFormat:@"observer = %@ and journalEntry = nil", _user];
    EOFetchSpecification *fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:@"Observation" qualifier:qual sortOrderings:nil];
    NSArray *pending = [ec objectsWithFetchSpecification:fetchSpec];
    
    BOOL changed = NO;
    for (Observation *obs in pending) {
        if ([obs.captureDate compare:cutoffDate] == NSOrderedAscending) {
            [ec deleteObject:obs];
            changed = YES;
        } else {
            BOOL exists = NO;
            for (Observation *existing in _unreviewedObservations) {
                if ([existing.observationId isEqualToString:obs.observationId]) {
                    exists = YES;
                    break;
                }
            }
            if (!exists) {
                [_unreviewedObservations addObject:obs];
            }
        }
    }
    if (changed) {
        NS_DURING {
            [ec saveChanges];
        } NS_HANDLER {
            NSLog(@"Failed to purge expired observations: %@", localException);
        } NS_ENDHANDLER;
    }
}

- (NSArray *)unreviewedObservations {
  return [[_unreviewedObservations copy] autorelease];
}

- (void)dealloc {
  [_user release];
  [_unreviewedObservations release];
  [_flashMessage release];
  [super dealloc];
}

- (NSDictionary *)stateDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[NSNumber numberWithInteger:_locationPermissionState] forKey:@"locationPermissionState"];
    if (_user && [_user uid]) {
        [dict setObject:[_user uid] forKey:@"userUid"];
    }
    NSMutableArray *obsArray = [NSMutableArray array];
    for (Observation *obs in _unreviewedObservations) {
        NSMutableDictionary *obsDict = [NSMutableDictionary dictionary];
        if (obs.observationId) [obsDict setObject:obs.observationId forKey:@"observationId"];
        if (obs.captureDate) [obsDict setObject:obs.captureDate forKey:@"captureDate"];
        if (obs.photoURLString) [obsDict setObject:obs.photoURLString forKey:@"photoURLString"];
        if (obs.latitude) [obsDict setObject:obs.latitude forKey:@"latitude"];
        if (obs.longitude) [obsDict setObject:obs.longitude forKey:@"longitude"];
        if (obs.accuracy) [obsDict setObject:obs.accuracy forKey:@"accuracy"];
        if (obs.bearing) [obsDict setObject:obs.bearing forKey:@"bearing"];
        [obsArray addObject:obsDict];
    }
    [dict setObject:obsArray forKey:@"unreviewedObservations"];
    if (_flashMessage) {
        [dict setObject:[_flashMessage dictionaryRepresentation] forKey:@"flashMessage"];
    }
    return dict;
}

- (void)restoreFromStateDictionary:(NSDictionary *)dict {
    if ([dict objectForKey:@"locationPermissionState"]) {
        _locationPermissionState = [[dict objectForKey:@"locationPermissionState"] integerValue];
    }
    if ([dict objectForKey:@"userUid"]) {
        NSString *uid = [dict objectForKey:@"userUid"];
        // We restore an unpersisted Observer with the UID, saveObserverWithError: will fetch it from DB when needed.
        Observer *obs = [[Observer alloc] init];
        [obs setUid:uid];
        [self setUser:obs];
        [obs release];
    }
    NSArray *obsArray = [dict objectForKey:@"unreviewedObservations"];
    if (obsArray) {
        for (NSDictionary *obsDict in obsArray) {
            Observation *obs = [[Observation alloc] init];
            if ([obsDict objectForKey:@"observationId"]) obs.observationId = [obsDict objectForKey:@"observationId"];
            if ([obsDict objectForKey:@"captureDate"]) obs.captureDate = [obsDict objectForKey:@"captureDate"];
            if ([obsDict objectForKey:@"photoURLString"]) obs.photoURLString = [obsDict objectForKey:@"photoURLString"];
            if ([obsDict objectForKey:@"latitude"]) obs.latitude = [obsDict objectForKey:@"latitude"];
            if ([obsDict objectForKey:@"longitude"]) obs.longitude = [obsDict objectForKey:@"longitude"];
            if ([obsDict objectForKey:@"accuracy"]) obs.accuracy = [obsDict objectForKey:@"accuracy"];
            if ([obsDict objectForKey:@"bearing"]) obs.bearing = [obsDict objectForKey:@"bearing"];
            BOOL alreadyExists = NO;
            for (Observation *existing in _unreviewedObservations) {
                if ([existing.observationId isEqualToString:obs.observationId]) {
                    alreadyExists = YES;
                    break;
                }
            }
            if (!alreadyExists) {
                [_unreviewedObservations addObject:obs];
                [self _tryPersistPendingObservation:obs];
            }
            [obs release];
        }
    }
    NSDictionary *flashDict = [dict objectForKey:@"flashMessage"];
    if (flashDict) {
        OTWFlashMessage *msg = [[OTWFlashMessage alloc] initWithDictionary:flashDict];
        [self setFlashMessage:msg];
        [msg release];
    }
}
@end
