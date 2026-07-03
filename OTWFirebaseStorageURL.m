// SPDX-License-Identifier: AGPL-3.0-or-later
//
// OTWFirebaseStorageURL.m - Parses Firebase Storage download URLs.
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

#import "OTWFirebaseStorageURL.h"

@implementation OTWFirebaseStorageURL

+ (NSString *)objectPathFromDownloadURL:(NSURL *)url {
    if (url == nil) {
        return nil;
    }
    NSArray *components = [url pathComponents];
    NSUInteger marker = [components indexOfObject:@"o"];
    if (marker == NSNotFound || marker + 1 >= [components count]) {
        return nil;
    }
    NSRange objectPathRange = NSMakeRange(marker + 1, [components count] - marker - 1);
    return [[components subarrayWithRange:objectPathRange] componentsJoinedByString:@"/"];
}

@end
