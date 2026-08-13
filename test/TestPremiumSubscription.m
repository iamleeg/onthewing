// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestPremiumSubscription.m - Tests for PremiumSubscription UI component
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
//

#import "PremiumSubscription.h"
#import <XCTest/XCTest.h>
#import "Observer.h"

@interface TestPremiumSubscription : XCTestCase
@end

@implementation TestPremiumSubscription

- (void)testDynamicPricingStringsFallback {
    WOContext *ctx = [[WOContext alloc] init];
    PremiumSubscription *component = [[PremiumSubscription alloc] initWithContext:ctx];
    XCTAssertNotNil(component);
    [component release];
    [ctx release];
}

@end
