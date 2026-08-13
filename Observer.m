// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Observer.m - Observer model representation
// Copyright (C) 2026 Graham Lee
//

#import "Observer.h"
#import "Observation.h"
#import "JournalEntry.h"
#import <EOControl/EOObserver.h>
#import <EOAccess/EOAccess.h>

NSUInteger const kFreeTierPhotoLimit = 50;

@implementation Observer

@synthesize uid = _uid;
@synthesize name = _name;
@synthesize email = _email;
@synthesize avatarUrl = _avatarUrl;
@synthesize token = _token;
@synthesize isPremium = _isPremium;
@synthesize subscriptionExpiryDate = _subscriptionExpiryDate;
@synthesize paymentProcessorCustomerId = _paymentProcessorCustomerId;
@synthesize journalEntries = _journalEntries;
@synthesize observations = _observations;

- (id)initWithUid:(NSString *)uid
             name:(NSString *)name
            email:(NSString *)email
        avatarUrl:(NSString *)avatarUrl
            token:(NSString *)token {
    self = [super init];
    if (self) {
        _uid = [uid copy];
        _name = [name copy];
        _email = [email copy];
        _avatarUrl = [avatarUrl copy];
        _token = [token copy];
        _isPremium = [[NSNumber alloc] initWithBool:NO];
        _subscriptionExpiryDate = nil;
        _paymentProcessorCustomerId = nil;
        _journalEntries = [[NSMutableArray alloc] init];
        _observations = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)setUid:(NSString *)uid {
    [self willChange];
    [_uid release];
    _uid = [uid copy];
}

- (void)setName:(NSString *)name {
    [self willChange];
    [_name release];
    _name = [name copy];
}

- (void)setEmail:(NSString *)email {
    [self willChange];
    [_email release];
    _email = [email copy];
}

- (void)setAvatarUrl:(NSString *)avatarUrl {
    [self willChange];
    [_avatarUrl release];
    _avatarUrl = [avatarUrl copy];
}

- (void)setToken:(NSString *)token {
    [self willChange];
    [_token release];
    _token = [token copy];
}

- (void)setIsPremium:(NSNumber *)isPremium {
    [self willChange];
    [_isPremium release];
    _isPremium = [isPremium retain];
}

- (void)setSubscriptionExpiryDate:(NSDate *)subscriptionExpiryDate {
    [self willChange];
    [_subscriptionExpiryDate release];
    _subscriptionExpiryDate = [subscriptionExpiryDate retain];
}

- (void)setPaymentProcessorCustomerId:(NSString *)paymentProcessorCustomerId {
    [self willChange];
    [_paymentProcessorCustomerId release];
    _paymentProcessorCustomerId = [paymentProcessorCustomerId copy];
}

- (void)setJournalEntries:(NSMutableArray *)journalEntries {
    [self willChange];
    [_journalEntries release];
    _journalEntries = [journalEntries retain];
}

- (NSUInteger)savedPhotoCountInEditingContext:(EOEditingContext *)ec {
    NSUInteger count = 0;
    for (JournalEntry *entry in [self journalEntries]) {
        for (Observation *observation in [entry observations]) {
            if ([observation photoURLString] != nil) {
                count++;
            }
        }
    }
    return count;
}

- (NSUInteger)remainingPhotoQuotaInEditingContext:(EOEditingContext *)ec {
    if ([self.isPremium boolValue]) {
        return NSUIntegerMax;
    }
    NSUInteger saved = [self savedPhotoCountInEditingContext:ec];
    return saved >= kFreeTierPhotoLimit ? 0 : (kFreeTierPhotoLimit - saved);
}

- (void)subscribeToPremium:(NSString *)option paymentDetails:(NSString *)paymentDetails {
    NSAssert(![self.isPremium boolValue], @"Precondition failed: Observer is already premium");
    self.isPremium = [NSNumber numberWithBool:YES];
}

- (void)cancelPremiumSubscription {
    NSAssert([self.isPremium boolValue], @"Precondition failed: Observer is not premium");
    // Actual expiry logic goes here; for now, they remain premium until expiration
}

- (void)handlePaymentRenewal:(BOOL)success {
    if (success) {
        self.isPremium = [NSNumber numberWithBool:YES];
    }
}

- (void)dealloc {
    [_uid release];
    [_name release];
    [_email release];
    [_avatarUrl release];
    [_token release];
    [_isPremium release];
    [_subscriptionExpiryDate release];
    [_paymentProcessorCustomerId release];
    [_journalEntries release];
    [_observations release];
    [super dealloc];
}

@end

