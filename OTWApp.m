// SPDX-License-Identifier: AGPL-3.0-or-later
//
// OTWApp.m - Application class
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

#import "OTWApp.h"

@implementation OTWApp

- (id)init {
  if ((self = [super init])) {
    [WOMessage setDefaultEncoding:NSUTF8StringEncoding];
    NSString *directActionHandlerKey =
        [[self class] directActionRequestHandlerKey];
    WORequestHandler *directActionHandler =
        [self requestHandlerForKey:directActionHandlerKey];
    [self setDefaultRequestHandler:directActionHandler];
  }
  return self;
}

+ (NSNumber *)sessionTimeOut {
  return [NSNumber numberWithInt:60];
}

@end
