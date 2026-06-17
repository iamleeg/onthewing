// SPDX-License-Identifier: AGPL-3.0-or-later
//
// FirebaseLogin.m - Firebase login component
// Copyright (C) 2026 Graham Lee
//

#import "FirebaseLogin.h"
#import "Session.h"
#import "Observer.h"
#import <EOControl/EOControl.h>
#import <EOAccess/EOAccess.h>
#import <EOAccess/EOUtilities.h>

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
    NSString *uid = [self uid];
    if (uid && [uid length] > 0) {
        Observer *user = nil;
        BOOL dbSuccess = NO;
        
        NS_DURING {
            EOEditingContext *ec = [session editingContext];
            [ec lock];
            
            Observer *existingUser = nil;
            EOQualifier *qualifier = [EOQualifier qualifierWithQualifierFormat:@"uid = %@", uid];
            EOFetchSpecification *fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:@"Observer"
                                                                                           qualifier:qualifier
                                                                                       sortOrderings:nil];
            NSArray *results = [ec objectsWithFetchSpecification:fetchSpec];
            if ([results count] > 0) {
                existingUser = [results objectAtIndex:0];
            }

            if (existingUser == nil) {
                user = [ec createAndInsertInstanceOfEntityNamed:@"Observer"];
                [user setUid:uid];
                [user setName:[self displayName]];
                [user setEmail:[self email]];
                [user setAvatarUrl:[self avatarUrl]];
                [user setToken:[self token]];
                [ec saveChanges];
            } else {
                user = existingUser;
                BOOL changed = NO;
                NSString *newDisplayName = [self displayName];
                if (newDisplayName && [newDisplayName length] > 0) {
                    if ([user name] == nil || ![[user name] isEqualToString:newDisplayName]) {
                        [user setName:newDisplayName];
                        changed = YES;
                    }
                }
                NSString *newEmail = [self email];
                if (newEmail && [newEmail length] > 0) {
                    if ([user email] == nil || ![[user email] isEqualToString:newEmail]) {
                        [user setEmail:newEmail];
                        changed = YES;
                    }
                }
                NSString *newAvatarUrl = [self avatarUrl];
                if (newAvatarUrl && [newAvatarUrl length] > 0) {
                    if ([user avatarUrl] == nil || ![[user avatarUrl] isEqualToString:newAvatarUrl]) {
                        [user setAvatarUrl:newAvatarUrl];
                        changed = YES;
                    }
                }
                NSString *newToken = [self token];
                if (newToken && [newToken length] > 0) {
                    if ([user token] == nil || ![[user token] isEqualToString:newToken]) {
                        [user setToken:newToken];
                        changed = YES;
                    }
                }
                if (changed) {
                    [ec saveChanges];
                }
            }
            [ec unlock];
            dbSuccess = YES;
        }
        NS_HANDLER {
            NSLog(@"Database operation failed during login: %@. Falling back to memory-only user.", localException);
            user = nil;
        }
        NS_ENDHANDLER;
        
        if (!dbSuccess || user == nil) {
            user = [[[Observer alloc] initWithUid:uid
                                         name:[self displayName]
                                        email:[self email]
                                    avatarUrl:[self avatarUrl]
                                        token:[self token]] autorelease];
        }
        [session setUser:user];
    }
    return [self pageWithName:@"Main"];
}

@end

