// SPDX-License-Identifier: AGPL-3.0-or-later
//
// OTWFlashMessage.m - Flash Message class
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

#import "OTWFlashMessage.h"

@implementation OTWFlashMessage

@synthesize stringValue = _stringValue;
@synthesize severityLevel = _severityLevel;

- (instancetype)initWithStringValue:(NSString *)stringValue severityLevel:(OTWFlashMessageSeverity)severityLevel {
    self = [super init];
    if (self) {
        _stringValue = [stringValue copy];
        _severityLevel = severityLevel;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _stringValue = [[dict objectForKey:@"stringValue"] copy];
        _severityLevel = (OTWFlashMessageSeverity)[[dict objectForKey:@"severityLevel"] integerValue];
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.stringValue) {
        [dict setObject:self.stringValue forKey:@"stringValue"];
    }
    [dict setObject:[NSNumber numberWithInteger:self.severityLevel] forKey:@"severityLevel"];
    return dict;
}

- (void)dealloc {
    [_stringValue release];
    [super dealloc];
}

@end
