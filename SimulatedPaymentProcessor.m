// SPDX-License-Identifier: AGPL-3.0-or-later
//
// SimulatedPaymentProcessor.m - Simulated implementation of PaymentProcessor
// Copyright (C) 2026 Graham Lee
//

#import "SimulatedPaymentProcessor.h"

@implementation SimulatedPaymentProcessor

- (NSString *)checkoutURLForOption:(NSString *)option successURL:(NSString *)successURL cancelURL:(NSString *)cancelURL error:(NSError **)error {
    // In simulation mode, we instantly redirect to the success URL, appending a simulated session_id
    NSString *separator = [successURL rangeOfString:@"?"].location == NSNotFound ? @"?" : @"&";
    return [NSString stringWithFormat:@"%@%@session_id=simulated_session_12345", successURL, separator];
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
