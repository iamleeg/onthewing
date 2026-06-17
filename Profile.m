// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Profile.m - User Profile view component
// Copyright (C) 2026 Graham Lee
//

#import "Profile.h"
#import "Session.h"
#import "Observer.h"
#import <EOControl/EOControl.h>

@implementation Profile

@synthesize updatedName = _updatedName;
@synthesize updatedEmail = _updatedEmail;

- (void)dealloc {
    [_updatedName release];
    [_updatedEmail release];
    [super dealloc];
}

- (id)showMain {
    return [self pageWithName:@"Main"];
}

- (BOOL)hasAvatar {
    Observer *user = [(Session *)[self session] user];
    return [user avatarUrl] != nil && [[user avatarUrl] length] > 0;
}

- (NSString *)userName {
    Observer *user = [(Session *)[self session] user];
    return [user name] && [[user name] length] > 0 ? [user name] : @"No name provided";
}

- (NSString *)userEmail {
    Observer *user = [(Session *)[self session] user];
    return [user email];
}

- (NSString *)avatarUrl {
    Observer *user = [(Session *)[self session] user];
    return [user avatarUrl];
}

- (NSString *)updatedName {
    if (_updatedName == nil) {
        Observer *user = [(Session *)[self session] user];
        return [user name];
    }
    return _updatedName;
}

- (void)setUpdatedName:(NSString *)name {
    [_updatedName release];
    _updatedName = [name copy];
}

- (NSString *)updatedEmail {
    if (_updatedEmail == nil) {
        Observer *user = [(Session *)[self session] user];
        return [user email];
    }
    return _updatedEmail;
}

- (void)setUpdatedEmail:(NSString *)email {
    [_updatedEmail release];
    _updatedEmail = [email copy];
}

- (id)updateProfile {
    Session *session = (Session *)[self session];
    Observer *user = [session user];
    if (user) {
        EOEditingContext *ec = [session editingContext];
        [ec lock];
        [user setName:[self updatedName]];
        [user setEmail:[self updatedEmail]];
        NS_DURING {
            [ec saveChanges];
        }
        NS_HANDLER {
            NSLog(@"Error updating profile in DB: %@", localException);
        }
        NS_ENDHANDLER;
        [ec unlock];
    }
    [self setUpdatedName:nil];
    [self setUpdatedEmail:nil];
    return nil;
}

- (id)deleteAccount {
    Session *session = (Session *)[self session];
    Observer *user = [session user];
    if (user) {
        EOEditingContext *ec = [session editingContext];
        [ec lock];
        NS_DURING {
            [ec deleteObject:user];
            [ec saveChanges];
        }
        NS_HANDLER {
            NSLog(@"Error deleting user from DB: %@", localException);
        }
        NS_ENDHANDLER;
        [ec unlock];
    }
    [session setUser:nil];
    return [self pageWithName:@"Main"];
}

@end
