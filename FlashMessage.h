// SPDX-License-Identifier: AGPL-3.0-or-later
//
// FlashMessage.h - Flash Message component
// Copyright (C) 2026 Graham Lee
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif
#import <WebObjects/WOComponent.h>
#import "OTWFlashMessage.h"

@interface FlashMessage : WOComponent {
    OTWFlashMessage *_message;
}

- (BOOL)hasMessage;
- (NSString *)messageClass;
- (NSString *)messageText;

@end
