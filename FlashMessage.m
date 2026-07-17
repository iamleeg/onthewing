// SPDX-License-Identifier: AGPL-3.0-or-later
//
// FlashMessage.m - Flash Message component
// Copyright (C) 2026 Graham Lee
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

#import "FlashMessage.h"
#import "Session.h"
#import <WebObjects/WOContext.h>

@implementation FlashMessage

- (void)appendToResponse:(WOResponse *)response inContext:(WOContext *)context {
    Session *s = (Session *)[self session];
    _message = [[s consumeFlashMessage] retain];
    [super appendToResponse:response inContext:context];
    [_message release];
    _message = nil;
}

- (BOOL)hasMessage {
    return _message != nil;
}

- (NSString *)messageClass {
    if (!_message) return @"";
    switch (_message.severityLevel) {
        case OTWFlashMessageSeverityError:
            return @"flash-message flash-error";
        case OTWFlashMessageSeveritySuccess:
            return @"flash-message flash-success";
        case OTWFlashMessageSeverityInfo:
        default:
            return @"flash-message flash-info";
    }
}

- (NSString *)messageText {
    return [_message stringValue];
}

- (void)dealloc {
    [_message release];
    [super dealloc];
}

@end
