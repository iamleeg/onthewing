// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestDirectAction.m - Tests for the DirectAction class
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

#import "DirectAction.h"
#import "TestOTWApp.h"
#import "Main.h"
#import <XCTest/XCTest.h>

@interface TestDirectAction : XCTestCase
@end

@implementation TestDirectAction

- (void)setUp {
    [super setUp];
    setenv("STRIPE_WEBHOOK_SECRET", "whsec_test_secret", 1);
}

- (void)tearDown {
    unsetenv("STRIPE_WEBHOOK_SECRET");
    [super tearDown];
}

- (void)testDefaultActionReturnsMainPage {
  OTWApp *app = [[TestOTWApp alloc] init];
  (void)app;
  WORequest *req = [[WORequest alloc] initWithMethod:@"GET"
                                                  uri:@"/"
                                          httpVersion:@"HTTP/1.1"
                                              headers:nil
                                              content:nil
                                             userInfo:nil];
  DirectAction *da = [[DirectAction alloc] initWithRequest:req];
  id results = [da defaultAction];
  XCTAssertTrue([results isKindOfClass:[Main class]]);
}

- (void)testStripeWebhookMissingSignature {
    NSString *bodyStr = @"{\"type\":\"checkout.session.completed\",\"data\":{\"object\":{\"client_reference_id\":\"mock_uid\",\"customer\":\"cus_123\"}}}";
    NSData *bodyData = [bodyStr dataUsingEncoding:NSUTF8StringEncoding];
    WORequest *req = [[WORequest alloc] initWithMethod:@"POST" uri:@"/wa/stripeWebhookAction" httpVersion:@"HTTP/1.1" headers:nil content:bodyData userInfo:nil];
    DirectAction *da = [[DirectAction alloc] initWithRequest:req];
    WOResponse *resp = (WOResponse *)[da stripeWebhookAction];
    XCTAssertEqual([resp status], 400);
}

- (void)testStripeWebhookInvalidSignature {
    NSString *bodyStr = @"{\"type\":\"checkout.session.completed\",\"data\":{\"object\":{\"client_reference_id\":\"mock_uid\",\"customer\":\"cus_123\"}}}";
    NSData *bodyData = [bodyStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *headers = @{@"Stripe-Signature": @[@"t=1234567890,v1=invalidsignature"]};
    WORequest *req = [[WORequest alloc] initWithMethod:@"POST" uri:@"/wa/stripeWebhookAction" httpVersion:@"HTTP/1.1" headers:headers content:bodyData userInfo:nil];
    DirectAction *da = [[DirectAction alloc] initWithRequest:req];
    WOResponse *resp = (WOResponse *)[da stripeWebhookAction];
    XCTAssertEqual([resp status], 400);
}

- (void)testStripeWebhookValidSignature {
    NSString *bodyStr = @"{\"type\":\"checkout.session.completed\",\"data\":{\"object\":{\"client_reference_id\":\"mock_uid\",\"customer\":\"cus_123\"}}}";
    NSData *bodyData = [bodyStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *headers = @{@"Stripe-Signature": @[@"t=1234567890,v1=e3b9414dadaf73d7dba408182f16523cd71539334ba706354e3943ef19e88dce"]};
    WORequest *req = [[WORequest alloc] initWithMethod:@"POST" uri:@"/wa/stripeWebhookAction" httpVersion:@"HTTP/1.1" headers:headers content:bodyData userInfo:nil];
    DirectAction *da = [[DirectAction alloc] initWithRequest:req];
    WOResponse *resp = (WOResponse *)[da stripeWebhookAction];
    XCTAssertEqual([resp status], 200);
}

- (void)testStripeWebhookLowercaseSignature {
    NSString *bodyStr = @"{\"type\":\"checkout.session.completed\",\"data\":{\"object\":{\"client_reference_id\":\"mock_uid\",\"customer\":\"cus_123\"}}}";
    NSData *bodyData = [bodyStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *headers = @{@"stripe-signature": @[@"t=1234567890,v1=e3b9414dadaf73d7dba408182f16523cd71539334ba706354e3943ef19e88dce"]};
    WORequest *req = [[WORequest alloc] initWithMethod:@"POST" uri:@"/wa/stripeWebhookAction" httpVersion:@"HTTP/1.1" headers:headers content:bodyData userInfo:nil];
    DirectAction *da = [[DirectAction alloc] initWithRequest:req];
    WOResponse *resp = (WOResponse *)[da stripeWebhookAction];
    XCTAssertEqual([resp status], 200);
}

- (void)testStripeWebhookSubscriptionUpdated {
    NSString *bodyStr = @"{\"type\":\"customer.subscription.updated\",\"data\":{\"object\":{\"customer\":\"cus_123\",\"current_period_end\":1787146137}}}";
    NSData *bodyData = [bodyStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *headers = @{@"Stripe-Signature": @[@"t=1234567890,v1=3920aaa3ad5e600944f08a9ee3c4d6cefedc074ee0da056e176d531a4047275b"]};
    WORequest *req = [[WORequest alloc] initWithMethod:@"POST" uri:@"/wa/stripeWebhookAction" httpVersion:@"HTTP/1.1" headers:headers content:bodyData userInfo:nil];
    DirectAction *da = [[DirectAction alloc] initWithRequest:req];
    WOResponse *resp = (WOResponse *)[da stripeWebhookAction];
    XCTAssertEqual([resp status], 200);
}

@end
