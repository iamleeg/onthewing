// SPDX-License-Identifier: AGPL-3.0-or-later
//
// User.h - User model representation
// Copyright (C) 2026 Graham Lee
//

#import <Foundation/Foundation.h>

@interface User : NSObject {
    NSString *_uid;
    NSString *_name;
    NSString *_email;
    NSString *_avatarUrl;
    NSString *_token;
}

@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *avatarUrl;
@property (nonatomic, copy) NSString *token;

- (id)initWithUid:(NSString *)uid
             name:(NSString *)name
            email:(NSString *)email
        avatarUrl:(NSString *)avatarUrl
            token:(NSString *)token;

@end
