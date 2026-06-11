// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestAuthActions.m - Tests for login and logout component actions
// Copyright (C) 2026 Graham Lee
//

#import "FirebaseLogin.h"
#import "FirebaseProfile.h"
#import "Session.h"
#import "User.h"
#import "OTWApp.h"
#import "Main.h"
#import <XCTest/XCTest.h>

@interface TestAuthActions : XCTestCase
{
    OTWApp *_app;
    WORequest *_req;
    WOContext *_ctx;
    Session *_s;
}
@end

@implementation TestAuthActions

- (void)setUp {
    _app = [[OTWApp alloc] init];
    _req = [[WORequest alloc] initWithMethod:@"GET"
                                         uri:@"/"
                                 httpVersion:@"HTTP/1.1"
                                     headers:nil
                                     content:nil
                                    userInfo:nil];
    _ctx = [[WOContext alloc] initWithRequest:_req];
    _s = (Session *)[_ctx session];
}

- (void)tearDown {
    [_ctx release]; _ctx = nil;
    _s = nil;
    [_req release]; _req = nil;
    [_app release]; _app = nil;
}

- (void)testFirebaseLoginAction {
    FirebaseLogin *loginComponent = [[FirebaseLogin alloc] initWithContext:_ctx];
    
    [loginComponent setUid:@"uid-123"];
    [loginComponent setDisplayName:@"John Doe"];
    [loginComponent setEmail:@"john@example.com"];
    [loginComponent setAvatarUrl:@"http://example.com/photo.jpg"];
    [loginComponent setToken:@"jwt-token-456"];
    
    id nextPage = [loginComponent login];
    XCTAssertEqualObjects([nextPage class], [Main class]);
    
    User *user = [_s user];
    XCTAssertNotNil(user);
    XCTAssertEqualObjects([user uid], @"uid-123");
    XCTAssertEqualObjects([user name], @"John Doe");
    XCTAssertEqualObjects([user email], @"john@example.com");
    XCTAssertEqualObjects([user avatarUrl], @"http://example.com/photo.jpg");
    XCTAssertEqualObjects([user token], @"jwt-token-456");
    
    [loginComponent release];
}

- (void)testFirebaseProfileLogoutAction {
    User *user = [[User alloc] initWithUid:@"uid-123"
                                      name:@"John Doe"
                                     email:@"john@example.com"
                                 avatarUrl:nil
                                     token:@"token"];
    [_s setUser:user];
    XCTAssertNotNil([_s user]);
    
    FirebaseProfile *profileComponent = [[FirebaseProfile alloc] initWithContext:_ctx];
    id nextPage = [profileComponent logout];
    
    XCTAssertEqualObjects([nextPage class], [Main class]);
    XCTAssertNil([_s user]);
    
    [profileComponent release];
    [user release];
}

@end
