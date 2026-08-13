// SPDX-License-Identifier: AGPL-3.0-or-later
//
// StripePaymentProcessor.h - Stripe implementation of PaymentProcessor
// Copyright (C) 2026 Graham Lee
//

#import <Foundation/Foundation.h>
#import "PaymentProcessor.h"

@interface StripePaymentProcessor : NSObject <PaymentProcessor>

@property (nonatomic, copy) NSString *secretKey;

- (instancetype)initWithSecretKey:(NSString *)secretKey;

// Helper to construct authenticated requests
- (NSMutableURLRequest *)requestWithURLString:(NSString *)urlString method:(NSString *)method;

@end
