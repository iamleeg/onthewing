// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Profile.m - User Profile view component
// Copyright (C) 2026 Graham Lee
//

#import "Profile.h"
#import "Session.h"
#import "User.h"

@implementation Profile

- (id)showMain {
    return [self pageWithName:@"Main"];
}

- (BOOL)hasAvatar {
    User *user = [(Session *)[self session] user];
    return [user avatarUrl] != nil && [[user avatarUrl] length] > 0;
}

- (NSString *)userName {
    User *user = [(Session *)[self session] user];
    return [user name] && [[user name] length] > 0 ? [user name] : @"No name provided";
}

- (NSString *)userEmail {
    User *user = [(Session *)[self session] user];
    return [user email];
}

- (NSString *)avatarUrl {
    User *user = [(Session *)[self session] user];
    return [user avatarUrl];
}

@end
