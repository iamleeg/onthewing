// SPDX-License-Identifier: AGPL-3.0-or-later
//
// PremiumSubscription.m - Premium subscription management UI
// Copyright (C) 2026 Graham Lee
//

#import "PremiumSubscription.h"
#import "Session.h"
#import "Main.h"
#import "OTWFlashMessage.h"
#import "OTWCurrency.h"
#import "StripePaymentProcessor.h"
#import "SimulatedPaymentProcessor.h"
#import "OTWRedirect.h"

@implementation PremiumSubscription

@synthesize observer = _observer;
@synthesize monthlyButtonText = _monthlyButtonText;
@synthesize annualButtonText = _annualButtonText;

- (void)dealloc {
    [_monthlyButtonText release];
    [_annualButtonText release];
    [_observer release];
    [super dealloc];
}

- (void)awake {
    [super awake];
    Session *session = (Session *)[self session];
    self.observer = [session user];
    
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"subscriptions.plist"];
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:path];
    if (config) {
        NSDictionary *monthly = [config objectForKey:@"monthly"];
        NSDecimalNumber *monthlyAmount = [NSDecimalNumber decimalNumberWithString:[monthly objectForKey:@"amount"]];
        OTWCurrency *monthlyCurrency = [[[OTWCurrency alloc] initWithAmount:monthlyAmount currencyCode:[monthly objectForKey:@"currency"]] autorelease];
        self.monthlyButtonText = [NSString stringWithFormat:@"%@ (%@/%@)", [monthly objectForKey:@"title"], [monthlyCurrency formattedString], [monthly objectForKey:@"interval"]];
        
        NSDictionary *annual = [config objectForKey:@"annual"];
        NSDecimalNumber *annualAmount = [NSDecimalNumber decimalNumberWithString:[annual objectForKey:@"amount"]];
        OTWCurrency *annualCurrency = [[[OTWCurrency alloc] initWithAmount:annualAmount currencyCode:[annual objectForKey:@"currency"]] autorelease];
        self.annualButtonText = [NSString stringWithFormat:@"%@ (%@/%@)", [annual objectForKey:@"title"], [annualCurrency formattedString], [annual objectForKey:@"interval"]];
    } else {
        self.monthlyButtonText = @"Subscribe Monthly (£4.99/mo)";
        self.annualButtonText = @"Subscribe Annually (£49.99/yr)";
    }
}

- (BOOL)isPremium {
    return [[self.observer isPremium] boolValue];
}

- (NSString *)subscriptionExpiryString {
    NSDate *expiry = [self.observer subscriptionExpiryDate];
    if (expiry) {
        NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setTimeStyle:NSDateFormatterNoStyle];
        return [formatter stringFromDate:expiry];
    }
    return @"Unknown";
}

- (WOComponent *)initiateSubscriptionForOption:(NSString *)option {
    Session *session = (Session *)[self session];
    NSString *paymentProcessorEnv = [[[NSProcessInfo processInfo] environment] objectForKey:@"PAYMENT_PROCESSOR"];
    id<PaymentProcessor> processor = nil;
    
    if ([paymentProcessorEnv isEqualToString:@"simulator"]) {
        processor = [[[SimulatedPaymentProcessor alloc] init] autorelease];
    } else {
        NSString *secretKey = [[[NSProcessInfo processInfo] environment] objectForKey:@"STRIPE_SECRET_KEY"];
        if (!secretKey) {
            OTWFlashMessage *msg = [[[OTWFlashMessage alloc] initWithStringValue:@"Error: STRIPE_SECRET_KEY is not configured." severityLevel:OTWFlashMessageSeverityError] autorelease];
            [session setFlashMessage:msg];
            return nil;
        }
        processor = [[[StripePaymentProcessor alloc] initWithSecretKey:secretKey] autorelease];
    }
    
    WOContext *ctx = [self context];
    NSString *successURL = [ctx urlWithRequestHandlerKey:[WOApplication directActionRequestHandlerKey] path:@"paymentSucceeded" queryString:nil];
    NSString *cancelURL = [ctx urlWithRequestHandlerKey:[WOApplication directActionRequestHandlerKey] path:@"paymentCanceled" queryString:nil];
    
    // Stripe requires absolute URLs. We must correctly determine the host and port.
    NSString *host = [[ctx request] headerForKey:@"x-forwarded-host"];
    if (!host) {
        host = [[ctx request] headerForKey:@"http_x_forwarded_host"];
    }
    if (!host) {
        host = [[ctx request] headerForKey:@"host"];
    }
    if (!host) host = @"localhost:8080";
    if ([host isEqualToString:@"localhost"]) {
        host = @"localhost:8080";
    }
    
    NSString *scheme = @"http";
    // Check if behind a proxy that sets X-Forwarded-Proto
    NSString *forwardedProto = [[ctx request] headerForKey:@"x-forwarded-proto"];
    if (!forwardedProto) {
        forwardedProto = [[ctx request] headerForKey:@"http_x_forwarded_proto"];
    }
    if (forwardedProto) scheme = forwardedProto;
    
    NSString *absSuccessURL = [NSString stringWithFormat:@"%@://%@%@", scheme, host, successURL];
    NSString *absCancelURL = [NSString stringWithFormat:@"%@://%@%@", scheme, host, cancelURL];
    
    NSError *error = nil;
    NSString *checkoutURL = [processor checkoutURLForOption:option userId:self.observer.uid successURL:absSuccessURL cancelURL:absCancelURL error:&error];
    
    if (checkoutURL) {
        OTWRedirect *redirect = (OTWRedirect *)[self pageWithName:@"OTWRedirect"];
        [redirect setUrl:checkoutURL];
        return redirect;
    } else {
        NSString *correlationID = [[NSUUID UUID] UUIDString];
        NSLog(@"[CorrelationID: %@] Failed to create checkout session: %@", correlationID, error);
        
        NSString *errMsg = error ? [error localizedDescription] : @"Unknown error creating checkout session.";
        OTWFlashMessage *msg = [[[OTWFlashMessage alloc] initWithStringValue:[NSString stringWithFormat:@"Error: %@ (Correlation ID: %@)", errMsg, correlationID] severityLevel:OTWFlashMessageSeverityError] autorelease];
        [session setFlashMessage:msg];
        return nil;
    }
}

- (WOComponent *)subscribeMonthly {
    return [self initiateSubscriptionForOption:@"monthly"];
}

- (WOComponent *)subscribeAnnual {
    return [self initiateSubscriptionForOption:@"annual"];
}

- (WOComponent *)cancelSubscription {
    Session *session = (Session *)[self session];
    NSString *paymentProcessorEnv = [[[NSProcessInfo processInfo] environment] objectForKey:@"PAYMENT_PROCESSOR"];
    id<PaymentProcessor> processor = nil;
    
    if ([paymentProcessorEnv isEqualToString:@"simulator"]) {
        processor = [[[SimulatedPaymentProcessor alloc] init] autorelease];
    } else {
        NSString *secretKey = [[[NSProcessInfo processInfo] environment] objectForKey:@"STRIPE_SECRET_KEY"];
        if (!secretKey) {
            OTWFlashMessage *msg = [[[OTWFlashMessage alloc] initWithStringValue:@"Error: STRIPE_SECRET_KEY is not configured." severityLevel:OTWFlashMessageSeverityError] autorelease];
            [session setFlashMessage:msg];
            return nil;
        }
        processor = [[[StripePaymentProcessor alloc] initWithSecretKey:secretKey] autorelease];
    }
    
    // Attempt cancellation
    NSError *error = nil;
    NSString *customerId = [[self observer] paymentProcessorCustomerId];
    if (!customerId) {
        // Fallback: just remove premium locally if they don't have a known processor ID?
        // Wait, for this demo we just cancel it.
        [[self observer] cancelPremiumSubscription];
        [[session editingContext] saveChanges];
        OTWFlashMessage *msg = [[[OTWFlashMessage alloc] initWithStringValue:@"Membership cancelled." severityLevel:OTWFlashMessageSeverityInfo] autorelease];
        [session setFlashMessage:msg];
        return nil;
    }
    
    BOOL success = [processor cancelAutoRenewalForCustomer:customerId error:&error];
    if (success) {
        [[self observer] cancelPremiumSubscription];
        [[session editingContext] saveChanges];
        OTWFlashMessage *msg = [[[OTWFlashMessage alloc] initWithStringValue:@"Membership cancelled successfully." severityLevel:OTWFlashMessageSeverityInfo] autorelease];
        [session setFlashMessage:msg];
    } else {
        NSString *correlationID = [[NSUUID UUID] UUIDString];
        NSLog(@"[CorrelationID: %@] Failed to cancel subscription: %@", correlationID, error);
        
        NSString *errMsg = error ? [error localizedDescription] : @"Unknown error cancelling subscription.";
        OTWFlashMessage *msg = [[[OTWFlashMessage alloc] initWithStringValue:[NSString stringWithFormat:@"Error cancelling: %@ (Correlation ID: %@)", errMsg, correlationID] severityLevel:OTWFlashMessageSeverityError] autorelease];
        [session setFlashMessage:msg];
    }
    
    return nil;
}

- (WOComponent *)goBack {
    Main *nextPage = (Main *)[self pageWithName:@"Main"];
    return nextPage;
}

@end
