// SPDX-License-Identifier: AGPL-3.0-or-later
//
// CompassSVGGenerator.h - Generates SVG representation of a compass needle based on bearing.
// Copyright (C) 2026 Graham Lee
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License,
// or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.

#import <Foundation/Foundation.h>

@interface CompassSVGGenerator : NSObject

/**
 * Generates an SVG string representing a compass.
 * If bearing is nil, returns an empty string.
 * @param bearing The compass bearing in degrees (0-360).
 * @return An SVG string or an empty string if bearing is nil.
 */
- (NSString *)svgForBearing:(NSNumber *)bearing;

@end
