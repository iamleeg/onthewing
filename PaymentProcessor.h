// SPDX-License-Identifier: AGPL-3.0-or-later
//
// PaymentProcessor.h - Facade for payment processing
// Copyright (C) 2026 Graham Lee
//

#import <Foundation/Foundation.h>

@protocol PaymentProcessor <NSObject>

/**
 * Validates the payment with the specified details for the given subscription option.
 * 
 * @param paymentDetails An opaque string representing the payment token or session ID.
 * @param option The subscription tier or option being purchased (e.g., "monthly", "annual").
 * @param error Out parameter for error details.
 * @return YES if validation succeeds, NO otherwise.
 */
- (BOOL)validatePaymentWithDetails:(NSString *)paymentDetails option:(NSString *)option error:(NSError **)error;

/**
 * Cancels the auto-renewal for the specified customer.
 * 
 * @param customerId The opaque identifier for the customer at the payment processor.
 * @param error Out parameter for error details.
 * @return YES if cancellation is successfully initiated, NO otherwise.
 */
- (BOOL)cancelAutoRenewalForCustomer:(NSString *)customerId error:(NSError **)error;

@end
