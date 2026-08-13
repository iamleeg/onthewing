// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestSimulatedPaymentProcessor.m - Tests for SimulatedPaymentProcessor
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

#import "SimulatedPaymentProcessor.h"
#import <XCTest/XCTest.h>

@interface TestSimulatedPaymentProcessor : XCTestCase
@end

@implementation TestSimulatedPaymentProcessor

- (void)testCheckoutURLForOption {
    SimulatedPaymentProcessor *processor = [[SimulatedPaymentProcessor alloc] init];
    NSError *error = nil;
    NSString *checkoutURL = [processor checkoutURLForOption:@"monthly" userId:@"user123" successURL:@"http://localhost/success" cancelURL:@"http://localhost/cancel" error:&error];
    
    XCTAssertNil(error);
    XCTAssertNotNil(checkoutURL);
    XCTAssertTrue([checkoutURL hasPrefix:@"http://localhost/success?session_id=simulated_session_12345"]);
    
    [processor release];
}

- (void)testCancelAutoRenewal {
    SimulatedPaymentProcessor *processor = [[SimulatedPaymentProcessor alloc] init];
    NSError *error = nil;
    BOOL success = [processor cancelAutoRenewalForCustomer:@"simulated_cus_123" error:&error];
    XCTAssertTrue(success);
    XCTAssertNil(error);
    [processor release];
}

@end
