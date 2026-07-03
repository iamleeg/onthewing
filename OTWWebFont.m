// SPDX-License-Identifier: AGPL-3.0-or-later
//
// OTWWebFont.m - A component that loads the app's Google Fonts.
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

#import "OTWWebFont.h"

@implementation OTWWebFont

- (void)appendToResponse:(WOResponse *)response inContext:(WOContext *)context {
    NSString *tags =
        @"<link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">\n"
        @"<link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>\n"
        @"<link href=\"https://fonts.googleapis.com/css2?family=Fira+Mono:wght@400;500;700&family=Inter:ital,opsz,wght@0,14..32,100..900;1,14..32,100..900&family=Lora:ital,wght@0,400..700;1,400..700&family=Oswald:wght@200..700&display=swap\" rel=\"stylesheet\">\n";
    [response appendContentString:tags];
}

@end
