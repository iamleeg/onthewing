// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestStripePaymentProcessor.m - Tests for StripePaymentProcessor
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

#import "StripePaymentProcessor.h"
#import <XCTest/XCTest.h>

@interface TestStripePaymentProcessor : XCTestCase
@end

@implementation TestStripePaymentProcessor

- (void)testInitWithSecretKey {
    StripePaymentProcessor *processor = [[StripePaymentProcessor alloc] initWithSecretKey:@"sk_test_123"];
    XCTAssertEqualObjects(processor.secretKey, @"sk_test_123");
    [processor release];
}

- (void)testRequestWithURLString {
    StripePaymentProcessor *processor = [[StripePaymentProcessor alloc] initWithSecretKey:@"sk_test_123"];
    NSMutableURLRequest *req = [processor requestWithURLString:@"https://api.stripe.com/v1/test" method:@"POST"];
    
    XCTAssertEqualObjects([req HTTPMethod], @"POST");
    XCTAssertEqualObjects([[req URL] absoluteString], @"https://api.stripe.com/v1/test");
    
    // Auth string: "sk_test_123:"
    // Base64 of "sk_test_123:" is "c2tfdGVzdF8xMjM6"
    NSString *authHeader = [req valueForHTTPHeaderField:@"Authorization"];
    XCTAssertEqualObjects(authHeader, @"Basic c2tfdGVzdF8xMjM6");
    
    NSString *versionHeader = [req valueForHTTPHeaderField:@"Stripe-Version"];
    XCTAssertEqualObjects(versionHeader, @"2023-10-16");
    
    [processor release];
}

@end
