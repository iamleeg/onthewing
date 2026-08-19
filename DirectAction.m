// SPDX-License-Identifier: AGPL-3.0-or-later
//
// DirectAction.m - Direct action handler
// Copyright (C) 2026 Graham Lee
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
#import <Foundation/Foundation.h>
#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#import "DirectAction.h"
#import "Session.h"
#import "OTWFlashMessage.h"
#import "Observer.h"
#import <EOControl/EOControl.h>
#include <gnutls/gnutls.h>
#include <gnutls/crypto.h>

@implementation DirectAction

- defaultAction {
  return [self pageWithName:@"Main"];
}

- (id)paymentSucceededAction {
    Session *session = (Session *)[self session];
    OTWFlashMessage *msg = [[[OTWFlashMessage alloc] initWithStringValue:@"Subscription process completed. Awaiting confirmation..." severityLevel:OTWFlashMessageSeverityInfo] autorelease];
    [session setFlashMessage:msg];
    return [self pageWithName:@"Profile"];
}

- (id)paymentCanceledAction {
    Session *session = (Session *)[self session];
    OTWFlashMessage *msg = [[[OTWFlashMessage alloc] initWithStringValue:@"Subscription cancelled." severityLevel:OTWFlashMessageSeverityError] autorelease];
    [session setFlashMessage:msg];
    return [self pageWithName:@"PremiumSubscription"];
}

- (WOResponse *)errorResponseWithStatus:(int)status reason:(NSString *)reason {
    NSString *correlationId = [[NSProcessInfo processInfo] globallyUniqueString];
    NSLog(@"Webhook error %d [%@]: %@", status, correlationId, reason);
    WOResponse *resp = [[[WOResponse alloc] init] autorelease];
    [resp setStatus:status];
    [resp appendContentString:[NSString stringWithFormat:@"%@. Correlation ID: %@", reason, correlationId]];
    return resp;
}

- (id)stripeWebhookAction {
    GSWRequest *req = [self request];
    NSData *body = [req content];
    
    NSError *error = nil;
    const char *secretEnv = getenv("STRIPE_WEBHOOK_SECRET");
    NSString *secret = secretEnv ? [NSString stringWithUTF8String:secretEnv] : nil;
    if (secret && [secret length] > 0) {
        NSString *signatureHeader = [req headerForKey:@"stripe-signature"];
        if (!signatureHeader) {
            signatureHeader = [req headerForKey:@"Stripe-Signature"];
        }
        
        if (!signatureHeader) {
            return [self errorResponseWithStatus:400 reason:@"Missing Stripe-Signature header"];
        }
        
        NSArray *components = [signatureHeader componentsSeparatedByString:@","];
        NSString *timestamp = nil;
        NSString *signature = nil;
        for (NSString *comp in components) {
            NSString *trimmed = [comp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([trimmed hasPrefix:@"t="]) {
                timestamp = [trimmed substringFromIndex:2];
            } else if ([trimmed hasPrefix:@"v1="]) {
                signature = [trimmed substringFromIndex:3];
            }
        }
        
        if (!timestamp || !signature) {
            return [self errorResponseWithStatus:400 reason:[NSString stringWithFormat:@"Invalid Stripe-Signature format: %@", signatureHeader]];
        }
        
        NSString *bodyStr = [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease];
        NSString *signedPayloadStr = [NSString stringWithFormat:@"%@.%@", timestamp, bodyStr];
        NSData *signedPayload = [signedPayloadStr dataUsingEncoding:NSUTF8StringEncoding];
        NSData *keyData = [secret dataUsingEncoding:NSUTF8StringEncoding];
        
        unsigned char mac[32];
        gnutls_hmac_fast(GNUTLS_MAC_SHA256, [keyData bytes], [keyData length], [signedPayload bytes], [signedPayload length], mac);
        
        NSMutableString *hexMac = [NSMutableString stringWithCapacity:64];
        for(int i = 0; i < 32; i++) {
            [hexMac appendFormat:@"%02x", mac[i]];
        }
        
        if (![signature isEqualToString:hexMac]) {
            return [self errorResponseWithStatus:400 reason:[NSString stringWithFormat:@"Signature mismatch. Expected: %@, Got: %@", hexMac, signature]];
        }
    }

    NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:body options:0 error:&error];
    if (!payload || error) {
        return [self errorResponseWithStatus:400 reason:[NSString stringWithFormat:@"Failed to parse JSON payload. Error: %@", error]];
    }
    
    NSString *type = [payload objectForKey:@"type"];
    NSDictionary *dataObj = [[payload objectForKey:@"data"] objectForKey:@"object"];
    
    EOEditingContext *ec = [[[EOEditingContext alloc] init] autorelease];
    
    NS_DURING {
        if ([type isEqualToString:@"checkout.session.completed"]) {
            NSString *uid = [dataObj objectForKey:@"client_reference_id"];
            NSString *customerId = [dataObj objectForKey:@"customer"];
            if (uid && customerId) {
                EOQualifier *qual = [EOQualifier qualifierWithQualifierFormat:@"uid = %@", uid];
                EOFetchSpecification *fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:@"Observer" qualifier:qual sortOrderings:nil];
                NSArray *results = [ec objectsWithFetchSpecification:fetchSpec];
                if ([results count] > 0) {
                    Observer *observer = [results objectAtIndex:0];
                    [observer setIsPremium:@(YES)];
                    [observer setPaymentProcessorCustomerId:customerId];
                    [ec saveChanges];
                }
            }
        } else if ([type isEqualToString:@"customer.subscription.deleted"]) {
            NSString *customerId = [dataObj objectForKey:@"customer"];
            if (customerId) {
                EOQualifier *qual = [EOQualifier qualifierWithQualifierFormat:@"paymentProcessorCustomerId = %@", customerId];
                EOFetchSpecification *fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:@"Observer" qualifier:qual sortOrderings:nil];
                NSArray *results = [ec objectsWithFetchSpecification:fetchSpec];
                if ([results count] > 0) {
                    Observer *observer = [results objectAtIndex:0];
                    [observer setIsPremium:@(NO)];
                    [ec saveChanges];
                }
            }
        } else if ([type isEqualToString:@"customer.subscription.created"] || [type isEqualToString:@"customer.subscription.updated"]) {
            NSString *customerId = [dataObj objectForKey:@"customer"];
            NSNumber *currentPeriodEnd = [dataObj objectForKey:@"current_period_end"];
            if (customerId && currentPeriodEnd) {
                EOQualifier *qual = [EOQualifier qualifierWithQualifierFormat:@"paymentProcessorCustomerId = %@", customerId];
                EOFetchSpecification *fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:@"Observer" qualifier:qual sortOrderings:nil];
                NSArray *results = [ec objectsWithFetchSpecification:fetchSpec];
                if ([results count] > 0) {
                    Observer *observer = [results objectAtIndex:0];
                    if ([currentPeriodEnd respondsToSelector:@selector(doubleValue)]) {
                        NSDate *expiryDate = [NSDate dateWithTimeIntervalSince1970:[currentPeriodEnd doubleValue]];
                        [observer setSubscriptionExpiryDate:expiryDate];
                        [ec saveChanges];
                    }
                }
            }
        }
        
        WOResponse *resp = [[[WOResponse alloc] init] autorelease];
        [resp setStatus:200];
        return resp;
    } NS_HANDLER {
        return [self errorResponseWithStatus:500 reason:[NSString stringWithFormat:@"An internal error occurred: %@", localException]];
    } NS_ENDHANDLER;
}

@end
