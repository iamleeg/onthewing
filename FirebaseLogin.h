// SPDX-License-Identifier: AGPL-3.0-or-later
//
// FirebaseLogin.h - Firebase login component
// Copyright (C) 2026 Graham Lee
//

#import <WebObjects/WebObjects.h>

@interface FirebaseLogin : GSWComponent {
    NSString *_uid;
    NSString *_displayName;
    NSString *_email;
    NSString *_avatarUrl;
    NSString *_token;
}

@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *avatarUrl;
@property (nonatomic, copy) NSString *token;

- (id)login;

@end
