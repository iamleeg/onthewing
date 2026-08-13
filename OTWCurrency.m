// SPDX-License-Identifier: AGPL-3.0-or-later
//
// OTWCurrency.m - Currency amount representation
// Copyright (C) 2026 Graham Lee
//

#import "OTWCurrency.h"

@implementation OTWCurrency

@synthesize amount = _amount;
@synthesize currencyCode = _currencyCode;

- (instancetype)initWithAmount:(NSDecimalNumber *)amount currencyCode:(NSString *)currencyCode {
    self = [super init];
    if (self) {
        _amount = [amount retain];
        _currencyCode = [currencyCode copy];
    }
    return self;
}

- (NSString *)formattedString {
    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setCurrencyCode:self.currencyCode];
    
    // Ensure we are using en_GB locale to avoid format inconsistencies
    NSLocale *locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"] autorelease];
    [formatter setLocale:locale];
    
    return [formatter stringFromNumber:self.amount];
}

- (void)dealloc {
    [_amount release];
    [_currencyCode release];
    [super dealloc];
}

@end
