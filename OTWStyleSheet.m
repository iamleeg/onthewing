// SPDX-License-Identifier: AGPL-3.0-or-later
//
// OTWStyleSheet.m - A component that adds a stylesheet from the app's resources.
//
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

#import "OTWStyleSheet.h"

@implementation OTWStyleSheet

@synthesize stylesheetName = _stylesheetName;

- (void)appendToResponse:(WOResponse *)response inContext:(WOContext *)context {
    NSString *url = [[context application] urlForResourceNamed:self.stylesheetName
                                                   inFramework:nil
                                                     languages:[context languages]
                                                       request:[context request]];
    NSString *tag = [NSString stringWithFormat:@"<link rel=\"stylesheet\" href=\"%@\" type=\"text/css\" />", url];
    [response appendContentString:tag];
}

@end
