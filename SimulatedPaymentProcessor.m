// SPDX-License-Identifier: AGPL-3.0-or-later
//
// SimulatedPaymentProcessor.m - Simulated implementation of PaymentProcessor
// Copyright (C) 2026 Graham Lee
//

#import "SimulatedPaymentProcessor.h"

@implementation SimulatedPaymentProcessor

- (NSString *)checkoutURLForOption:(NSString *)option userId:(NSString *)userId successURL:(NSString *)successURL cancelURL:(NSString *)cancelURL error:(NSError **)error {
    // In simulation mode, we simulate a webhook POST asynchronously, then immediately redirect the user to success.
    // In a real system, the webhook arrives independently. Here we'll simulate the webhook call manually if we had a webhook URL,
    // but actually, we can just let a background thread or a synchronous HTTP request hit our own webhook endpoint!
    // Since we don't easily know our own webhook URL in the model layer, we can rely on `SimulateWebhookCommand` or similar.
    NSString *separator = [successURL rangeOfString:@"?"].location == NSNotFound ? @"?" : @"&";
    return [NSString stringWithFormat:@"%@%@session_id=simulated_session_12345&client_reference_id=%@", successURL, separator, userId ? [userId stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] : @""];
}

- (BOOL)validatePaymentWithDetails:(NSString *)paymentDetails option:(NSString *)option error:(NSError **)error {
    if ([paymentDetails isEqualToString:@"simulated_session_12345"]) {
        return YES;
    }
    if (error) {
        *error = [NSError errorWithDomain:@"SimulationErrorDomain" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid simulated session"}];
    }
    return NO;
}

- (BOOL)cancelAutoRenewalForCustomer:(NSString *)customerId error:(NSError **)error {
    if ([customerId isEqualToString:@"simulated_customer_12345"] || customerId == nil) {
        return YES;
    }
    // Allow cancellation for any simulated customer for testing ease
    if ([customerId hasPrefix:@"simulated"]) {
        return YES;
    }
    if (error) {
        *error = [NSError errorWithDomain:@"SimulationErrorDomain" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Invalid simulated customer"}];
    }
    return NO;
}

@end
