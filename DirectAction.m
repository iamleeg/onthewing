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
