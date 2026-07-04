// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Main.m - Landing Page
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

#import "Main.h"
#import "Observation.h"
#import "Session.h"
#import "OTWApp.h"

@implementation Main

- (id)capture {
  id <ObservationUsing> capturePage = (id <ObservationUsing>)[self pageWithName:@"Capture"];
  [capturePage prepareFreshObservation];
  return capturePage;
}

- (id)reviewObservations {
  return [self pageWithName:@"ReviewObservations"];
}

- (id)browseJournal {
  return [self pageWithName:@"BrowseJournal"];
}

- (BOOL)hasObservations {
  Session *session = (Session *)[self session];
  return ([[session unreviewedObservations] count] > 0);
}

- (NSString *)reportPendingObservations {
  Session *session = (Session *)[self session];
  NSUInteger count = [[session unreviewedObservations] count];
  NSAssert(count > 0, @"Don't show pending observations if there aren't any");
  if (count == 1) {
    return @"There's an observation you can add to your journal!";
  } else {
    return [NSString stringWithFormat: @"You have %lu observations you can add to your journal!", count];
  }
}

- (BOOL)hasUser {
  Session *session = (Session *)[self session];
  return [session user] != nil;
}

- (BOOL)isAppReady {
  return [(OTWApp *)[self application] isDatabaseSchemaReady];
}

@end
