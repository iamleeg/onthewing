// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Observer.m - Observer model representation
// Copyright (C) 2026 Graham Lee
//

#import "Observer.h"
#import <EOControl/EOObserver.h>

@implementation Observer

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

- (void)setUid:(NSString *)uid {
    [self willChange];
    [_uid release];
    _uid = [uid copy];
}

- (void)setName:(NSString *)name {
    [self willChange];
    [_name release];
    _name = [name copy];
}

- (void)setEmail:(NSString *)email {
    [self willChange];
    [_email release];
    _email = [email copy];
}

- (void)setAvatarUrl:(NSString *)avatarUrl {
    [self willChange];
    [_avatarUrl release];
    _avatarUrl = [avatarUrl copy];
}

- (void)setToken:(NSString *)token {
    [self willChange];
    [_token release];
    _token = [token copy];
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

