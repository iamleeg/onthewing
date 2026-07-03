// SPDX-License-Identifier: AGPL-3.0-or-later
//
// OTWBearerToken.h - A resolved (possibly absent) OAuth2 bearer token.
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


// An object that represents the result of resolving credentials for an outbound request:
// either a real bearer token to attach, or the deliberate absence of one (the
// Firebase emulator doesn't check authentication tokens). When there's no token to use,
// -isEmpty returns YES.
@interface OTWBearerToken : NSObject
{
    NSString *_value;
}

+ (OTWBearerToken *)emptyToken;
+ (OTWBearerToken *)tokenWithValue:(NSString *)value;

@property (nonatomic, readonly) NSString *value;
@property (nonatomic, readonly) BOOL isEmpty;

@end
