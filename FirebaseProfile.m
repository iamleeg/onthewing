// SPDX-License-Identifier: AGPL-3.0-or-later
//
// FirebaseProfile.m - Firebase Profile/Logout component
// Copyright (C) 2026 Graham Lee
//

#import "FirebaseProfile.h"
#import "Session.h"

@implementation FirebaseProfile

- (id)showProfile {
    return [self pageWithName:@"Profile"];
}

- (id)logout {
    Session *session = (Session *)[self session];
    [session setUser:nil];
    [session terminate];
    return [self pageWithName:@"Main"];
}

@end
