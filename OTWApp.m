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

extern int GSWebNamingConv;
extern NSDictionary* globalMime;

+ (void)initialize {
  if (self == [OTWApp class]) {
    GSWebNamingConv = 1; // WONAMES_INDEX
    
    // Register custom MIME types for CSS and JS
    NSMutableDictionary *mimes = [globalMime mutableCopy];
    if (mimes == nil) {
      mimes = [[NSMutableDictionary alloc] init];
    }
    [mimes setObject:@"text/css" forKey:@"css"];
    [mimes setObject:@"application/javascript" forKey:@"js"];
    globalMime = [mimes copy];
    [mimes release];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *d = @{
      @"WOAdaptor" : @"WODefaultAdaptor",
      @"GSWAdaptor" : @"WODefaultAdaptor",
      @"WODirectActionRequestHandlerKey" : @"wa",
      @"GSWDirectActionRequestHandlerKey" : @"dr",
      @"WOComponentRequestHandlerKey" : @"wo",
      @"GSWComponentRequestHandlerKey" : @"cr",
      @"WOResourceRequestHandlerKey" : @"wr",
      @"GSWResourceRequestHandlerKey" : @"rr",
      @"WOPingActionRequestHandlerKey" : @"wlb",
      @"GSWPingActionRequestHandlerKey" : @"lb",
      @"WOStreamActionRequestHandlerKey" : @"wis",
      @"GSWStreamActionRequestHandlerKey" : @"sr",
      @"AjaxRequestHandlerKey" : @"ja",
      @"GSWContextClassName" : @"WOContext",
      @"WOContextClassName" : @"WOContext"
    };
    [defaults registerDefaults:d];
    [defaults synchronize];
  }
}

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

- (NSString *)contextClassName {
  return @"WOContext";
}

@end
