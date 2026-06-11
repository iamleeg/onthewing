// SPDX-License-Identifier: AGPL-3.0-or-later
//
// FirebaseLogin.m - Firebase login component
// Copyright (C) 2026 Graham Lee
//

#import "FirebaseLogin.h"
#import "Session.h"
#import "User.h"

@implementation FirebaseLogin

@synthesize uid = _uid;
@synthesize displayName = _displayName;
@synthesize email = _email;
@synthesize avatarUrl = _avatarUrl;
@synthesize token = _token;

- (void)dealloc {
    [_uid release];
    [_displayName release];
    [_email release];
    [_avatarUrl release];
    [_token release];
    [super dealloc];
}

- (id)login {
    Session *session = (Session *)[self session];
    if ([self uid] && [[self uid] length] > 0) {
        User *user = [[User alloc] initWithUid:[self uid]
                                          name:[self displayName]
                                         email:[self email]
                                     avatarUrl:[self avatarUrl]
                                         token:[self token]];
        [session setUser:user];
        [user release];
    }
    return [self pageWithName:@"Main"];
}

@end
