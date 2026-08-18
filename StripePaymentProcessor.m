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
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    if (json && [[json objectForKey:@"payment_status"] isEqualToString:@"paid"]) {
        return YES;
    }
    
    if (error) {
        *error = [NSError errorWithDomain:@"StripeErrorDomain" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Payment not paid."}];
    }
    return NO;
}

- (NSString *)checkoutURLForOption:(NSString *)option userId:(NSString *)userId successURL:(NSString *)successURL cancelURL:(NSString *)cancelURL error:(NSError **)error {
    NSString *urlString = @"https://api.stripe.com/v1/checkout/sessions";
    NSMutableURLRequest *request = [self requestWithURLString:urlString method:@"POST"];
    
    // Determine pricing data based on the option
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"subscriptions.plist"];
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:path];
    NSDictionary *optionConfig = [config objectForKey:option];
    
    if (!optionConfig) {
        if (error) {
            *error = [NSError errorWithDomain:@"StripeErrorDomain" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Invalid subscription option"}];
        }
        return nil;
    }
    
    // Calculate amount in cents/pence (e.g., 4.99 -> 499)
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:[optionConfig objectForKey:@"amount"]];
    NSDecimalNumber *multiplier = [NSDecimalNumber decimalNumberWithString:@"100"];
    int unitAmount = [[amount decimalNumberByMultiplyingBy:multiplier] intValue];
    NSString *currency = [[optionConfig objectForKey:@"currency"] lowercaseString];
    NSString *interval = [[optionConfig objectForKey:@"interval"] isEqualToString:@"yr"] ? @"year" : @"month";
    NSString *title = [optionConfig objectForKey:@"title"];
    
    NSMutableString *bodyStr = [NSMutableString string];
    [bodyStr appendString:@"mode=subscription"];
    [bodyStr appendFormat:@"&success_url=%@", [successURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    [bodyStr appendFormat:@"&cancel_url=%@", [cancelURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    if (userId) {
        [bodyStr appendFormat:@"&client_reference_id=%@", [userId stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    }
    
    [bodyStr appendFormat:@"&line_items[0][quantity]=1"];
    [bodyStr appendFormat:@"&line_items[0][price_data][currency]=%@", currency];
    [bodyStr appendFormat:@"&line_items[0][price_data][product_data][name]=%@", [title stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    [bodyStr appendFormat:@"&line_items[0][price_data][recurring][interval]=%@", interval];
    [bodyStr appendFormat:@"&line_items[0][price_data][unit_amount]=%d", unitAmount];
    [bodyStr appendString:@"&managed_payments[enabled]=false"];
    
    [request setHTTPBody:[bodyStr dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLResponse *response = nil;
    NSError *reqError = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&reqError];
    
    if (reqError) {
        if (error) *error = reqError;
        return nil;
    }
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (json && [json objectForKey:@"url"]) {
        return [json objectForKey:@"url"];
    }
    
    if (error) {
        *error = [NSError errorWithDomain:@"StripeErrorDomain" code:3 userInfo:@{NSLocalizedDescriptionKey: @"Failed to create checkout session."}];
    }
    return nil;
}

- (BOOL)cancelAutoRenewalForCustomer:(NSString *)customerId error:(NSError **)error {
    // 1. Fetch the customer's active subscriptions
    NSString *listUrlString = [NSString stringWithFormat:@"https://api.stripe.com/v1/subscriptions?customer=%@", customerId];
    NSMutableURLRequest *listReq = [self requestWithURLString:listUrlString method:@"GET"];
    
    NSURLResponse *response = nil;
    NSError *reqError = nil;
    NSData *listData = [NSURLConnection sendSynchronousRequest:listReq returningResponse:&response error:&reqError];
    
    if (reqError) {
        if (error) *error = reqError;
        return NO;
    }
    
    NSDictionary *listJson = [NSJSONSerialization JSONObjectWithData:listData options:0 error:NULL];
    NSArray *subscriptions = [listJson objectForKey:@"data"];
    
    if (!subscriptions || [subscriptions count] == 0) {
        if (error) *error = [NSError errorWithDomain:@"StripeErrorDomain" code:404 userInfo:@{NSLocalizedDescriptionKey: @"No active subscription found for this customer in Stripe."}];
        return NO;
    }
    
    NSString *subscriptionId = [[subscriptions objectAtIndex:0] objectForKey:@"id"];
    
    // 2. Cancel the subscription
    NSString *cancelUrlString = [NSString stringWithFormat:@"https://api.stripe.com/v1/subscriptions/%@", subscriptionId];
    NSMutableURLRequest *cancelReq = [self requestWithURLString:cancelUrlString method:@"DELETE"];
    
    NSData *cancelData = [NSURLConnection sendSynchronousRequest:cancelReq returningResponse:&response error:&reqError];
    if (reqError) {
        if (error) *error = reqError;
        return NO;
    }
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:cancelData options:0 error:NULL];
    
    if (json && [json objectForKey:@"error"]) {
        NSString *errMsg = [[json objectForKey:@"error"] objectForKey:@"message"];
        if (error) *error = [NSError errorWithDomain:@"StripeErrorDomain" code:400 userInfo:@{NSLocalizedDescriptionKey: errMsg ? errMsg : @"Unknown Stripe error."}];
        return NO;
    }
    
    if (json && [[json objectForKey:@"status"] isEqualToString:@"canceled"]) {
        return YES;
    }
    
    if (error) *error = [NSError errorWithDomain:@"StripeErrorDomain" code:500 userInfo:@{NSLocalizedDescriptionKey: @"Failed to parse Stripe cancel response."}];
    
    return NO;
}

- (void)dealloc {
    [_secretKey release];
    [super dealloc];
}

@end
