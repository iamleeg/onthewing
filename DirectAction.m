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

- (id)stripeWebhookAction {
    GSWRequest *req = [self request];
    NSData *body = [req content];
    
    NSError *error = nil;
    NSString *secret = [[[NSProcessInfo processInfo] environment] objectForKey:@"STRIPE_WEBHOOK_SECRET"];
    if (secret && [secret length] > 0) {
        NSString *signatureHeader = [req headerForKey:@"Stripe-Signature"];
        if (!signatureHeader) {
            WOResponse *resp = [[[WOResponse alloc] init] autorelease];
            [resp setStatus:400];
            return resp;
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
            WOResponse *resp = [[[WOResponse alloc] init] autorelease];
            [resp setStatus:400];
            return resp;
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
            WOResponse *resp = [[[WOResponse alloc] init] autorelease];
            [resp setStatus:400];
            return resp;
        }
    }

    NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:body options:0 error:&error];
    if (!payload || error) {
        WOResponse *resp = [[[WOResponse alloc] init] autorelease];
        [resp setStatus:400];
        return resp;
    }
    
    NSString *type = [payload objectForKey:@"type"];
    NSDictionary *dataObj = [[payload objectForKey:@"data"] objectForKey:@"object"];
    
    EOEditingContext *ec = [[[EOEditingContext alloc] init] autorelease];
    
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
    }
    
    WOResponse *resp = [[[WOResponse alloc] init] autorelease];
    [resp setStatus:200];
    return resp;
}

@end
