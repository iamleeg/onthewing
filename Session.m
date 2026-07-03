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

- (void)removeAllObservationsForReview {
  [_unreviewedObservations removeAllObjects];
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

- (NSArray *)unreviewedObservations {
  return [[_unreviewedObservations copy] autorelease];
}

- (void)dealloc {
  [_user release];
  [_unreviewedObservations release];
  [super dealloc];
}
@end
