// SPDX-License-Identifier: AGPL-3.0-or-later
//
// OTWBearerToken.m - A resolved (possibly absent) OAuth2 bearer token.
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

#import "OTWBearerToken.h"

@interface OTWBearerToken ()
- (id)initWithValue:(NSString *)value;
@end

@implementation OTWBearerToken

@synthesize value = _value;

+ (OTWBearerToken *)emptyToken {
    return [[[OTWBearerToken alloc] initWithValue:nil] autorelease];
}

+ (OTWBearerToken *)tokenWithValue:(NSString *)value {
    return [[[OTWBearerToken alloc] initWithValue:value] autorelease];
}

- (id)initWithValue:(NSString *)value {
    self = [super init];
    if (self) {
        _value = [value copy];
    }
    return self;
}

- (BOOL)isEmpty {
    return _value == nil;
}

- (void)dealloc {
    [_value release];
    [super dealloc];
}

@end
