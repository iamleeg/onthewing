// SPDX-License-Identifier: AGPL-3.0-or-later
//
// PremiumSubscription.h - Premium subscription management UI
// Copyright (C) 2026 Graham Lee
//

#import <WebObjects/WOComponent.h>
#import "Observer.h"

@interface PremiumSubscription : WOComponent {
    Observer *_observer;
    NSString *_monthlyButtonText;
    NSString *_annualButtonText;
}

@property (nonatomic, retain) Observer *observer;
@property (nonatomic, copy) NSString *monthlyButtonText;
@property (nonatomic, copy) NSString *annualButtonText;

- (BOOL)isPremium;
- (NSString *)subscriptionExpiryString;

- (WOComponent *)subscribeMonthly;
- (WOComponent *)subscribeAnnual;
- (WOComponent *)cancelSubscription;
- (WOComponent *)goBack;

@end
