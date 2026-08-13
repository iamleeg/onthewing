// SPDX-License-Identifier: AGPL-3.0-or-later
//
// StripePaymentProcessor.m - Stripe implementation of PaymentProcessor
// Copyright (C) 2026 Graham Lee
//

#import "StripePaymentProcessor.h"

@implementation StripePaymentProcessor

@synthesize secretKey = _secretKey;

- (instancetype)initWithSecretKey:(NSString *)secretKey {
    self = [super init];
    if (self) {
        _secretKey = [secretKey copy];
    }
    return self;
}

- (NSMutableURLRequest *)requestWithURLString:(NSString *)urlString method:(NSString *)method {
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:method];
    
    NSString *authStr = [NSString stringWithFormat:@"%@:", self.secretKey];
    NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
    // Base64 encode using NSDataBase64EncodingOptions
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:0]];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    [request setValue:@"2023-10-16" forHTTPHeaderField:@"Stripe-Version"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    return request;
}

- (BOOL)validatePaymentWithDetails:(NSString *)paymentDetails option:(NSString *)option error:(NSError **)error {
    // Here we would typically retrieve a Checkout Session by its ID (paymentDetails)
    // and verify that its payment_status is 'paid'.
    NSString *urlString = [NSString stringWithFormat:@"https://api.stripe.com/v1/checkout/sessions/%@", paymentDetails];
    NSMutableURLRequest *request = [self requestWithURLString:urlString method:@"GET"];
    
    NSURLResponse *response = nil;
    NSError *reqError = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&reqError];
    
    if (reqError) {
        if (error) *error = reqError;
        return NO;
    }
    
    // Parse JSON
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (json && [json[@"payment_status"] isEqualToString:@"paid"]) {
        return YES;
    }
    
    if (error) {
        *error = [NSError errorWithDomain:@"StripeErrorDomain" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Payment not paid."}];
    }
    return NO;
}

- (BOOL)cancelAutoRenewalForCustomer:(NSString *)customerId error:(NSError **)error {
    // Typically we would fetch the customer's active subscription and then cancel it.
    // For simplicity, assume customerId represents the subscription ID here or we look it up.
    // Stripe cancel API: DELETE /v1/subscriptions/{subscription_id}
    NSString *urlString = [NSString stringWithFormat:@"https://api.stripe.com/v1/subscriptions/%@", customerId];
    NSMutableURLRequest *request = [self requestWithURLString:urlString method:@"DELETE"];
    
    NSURLResponse *response = nil;
    NSError *reqError = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&reqError];
    
    if (reqError) {
        if (error) *error = reqError;
        return NO;
    }
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (json && [json[@"status"] isEqualToString:@"canceled"]) {
        return YES;
    }
    
    return NO;
}

- (void)dealloc {
    [_secretKey release];
    [super dealloc];
}

@end
