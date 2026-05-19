// SPDX-License-Identifier: AGPL-3.0-or-later
//
// AGPLFooter.m - Component that links to the product source code.
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

#import "AGPLFooter.h"

@implementation AGPLFooter

- (NSURL *)sourceURL {
  return [NSURL URLWithString:@"https://codeberg.org/leeg/onthewing"];
}
@end