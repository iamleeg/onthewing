// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Profile.h - User Profile view component
// Copyright (C) 2026 Graham Lee
//

#import <WebObjects/WebObjects.h>

@interface Profile : GSWComponent

- (id)showMain;
- (BOOL)hasAvatar;
- (NSString *)userName;
- (NSString *)userEmail;
- (NSString *)avatarUrl;

@end
