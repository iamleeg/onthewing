// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestUser.m - Tests for the User class and its session storage
// Copyright (C) 2026 Graham Lee
//

#import "User.h"
#import "Session.h"
#import <XCTest/XCTest.h>

@interface TestUser : XCTestCase
@end

@implementation TestUser

- (void)testUserInitialization {
    User *user = [[User alloc] initWithUid:@"test-uid-123"
                                      name:@"John Doe"
                                     email:@"john@example.com"
                                 avatarUrl:@"http://example.com/avatar.jpg"
                                     token:@"test-token-456"];
    
    XCTAssertEqualObjects([user uid], @"test-uid-123");
    XCTAssertEqualObjects([user name], @"John Doe");
    XCTAssertEqualObjects([user email], @"john@example.com");
    XCTAssertEqualObjects([user avatarUrl], @"http://example.com/avatar.jpg");
    XCTAssertEqualObjects([user token], @"test-token-456");
    
    [user release];
}

- (void)testSessionStoresUser {
    Session *session = [[Session alloc] init];
    XCTAssertNil([session user]);
    
    User *user = [[User alloc] initWithUid:@"test-uid"
                                      name:@"Jane Doe"
                                     email:@"jane@example.com"
                                 avatarUrl:nil
                                     token:@"token"];
    [session setUser:user];
    XCTAssertEqualObjects([session user], user);
    
    [session setUser:nil];
    XCTAssertNil([session user]);
    
    [user release];
    [session release];
}

@end
