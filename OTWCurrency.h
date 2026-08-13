// SPDX-License-Identifier: AGPL-3.0-or-later
//
// OTWCurrency.h - Currency amount representation
// Copyright (C) 2026 Graham Lee
//

#import <Foundation/Foundation.h>

@interface OTWCurrency : NSObject {
    NSDecimalNumber *_amount;
    NSString *_currencyCode;
}

@property (nonatomic, retain) NSDecimalNumber *amount;
@property (nonatomic, copy) NSString *currencyCode;

- (instancetype)initWithAmount:(NSDecimalNumber *)amount currencyCode:(NSString *)currencyCode;
- (NSString *)formattedString;

@end
