// SPDX-License-Identifier: AGPL-3.0-or-later
//
// User.m - User model representation
// Copyright (C) 2026 Graham Lee
//

#import "User.h"

@implementation User

@synthesize uid = _uid;
@synthesize name = _name;
@synthesize email = _email;
@synthesize avatarUrl = _avatarUrl;
@synthesize token = _token;

- (id)initWithUid:(NSString *)uid
             name:(NSString *)name
            email:(NSString *)email
        avatarUrl:(NSString *)avatarUrl
            token:(NSString *)token {
    self = [super init];
    if (self) {
        _uid = [uid copy];
        _name = [name copy];
        _email = [email copy];
        _avatarUrl = [avatarUrl copy];
        _token = [token copy];
    }
    return self;
}

- (void)dealloc {
    [_uid release];
    [_name release];
    [_email release];
    [_avatarUrl release];
    [_token release];
    [super dealloc];
}

@end
