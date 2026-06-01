// SPDX-License-Identifier: AGPL-3.0-or-later
//
// CompassSVGGenerator.m - Generates SVG representation of a compass needle based on bearing.
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

#import "CompassSVGGenerator.h"

@implementation CompassSVGGenerator

- (NSString *)svgForBearing:(NSNumber *)bearing {
    if (!bearing) {
        return @"";
    }

    double angle = [bearing doubleValue];
    
    // We use a 100x100 coordinate system. Center is at (50, 50).
    // North is Up (angle 0), which corresponds to the negative Y axis in SVG.
    
    return [NSString stringWithFormat:
        @"<svg width=\"100\" height=\"100\" viewBox=\"0 0 100 100\" xmlns=\"http://www.w3.org/2000/svg\">"
        @"  <!-- Compass Circle -->"
        @"  <circle cx=\"50\" cy=\"50\" r=\"45\" fill=\"none\" stroke=\"#666\" stroke-width=\"2\" />"
        @"  "
        @"  <!-- Cardinal Markers -->"
        @"  <text x=\"50\" y=\"18\" text-anchor=\"middle\" font-family=\"Arial\" font-size=\"12\" fill=\"#333\">N</text>"
        @"  <text x=\"50\" y=\"88\" text-anchor=\"middle\" font-family=\"Arial\" font-size=\"12\" fill=\"#333\">S</text>"
        @"  <text x=\"86\" y=\"54\" text-anchor=\"middle\" font-family=\"Arial\" font-size=\"12\" fill=\"#333\">E</text>"
        @"  <text x=\"14\" y=\"54\" text-anchor=\"middle\" font-family=\"Arial\" font-size=\"12\" fill=\"#333\">W</text>"
        @"  "
        @"  <!-- Needle -->"
        @"  <g transform=\"rotate(%.2f, 50, 50)\">"
        @"    <!-- Needle Shaft -->"
        @"    <line x1=\"50\" y1=\"50\" x2=\"50\" y2=\"20\" stroke=\"#000\" stroke-width=\"3\" />"
        @"    <!-- Arrowhead at the tip (North) -->"
        @"    <polygon points=\"46,30 54,30 50,20\" fill=\"#f00\" stroke=\"#000\" stroke-width=\"1\" />"
        @"  </g>"
        @"</svg>",
        angle];
}

@end
