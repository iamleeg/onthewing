// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestFirebaseAuthUI.m - Tests for the FirebaseAuthUI component.
// Copyright (C) 2026 Graham Lee
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

#import "FirebaseAuthUI.h"
#import "Session.h"
#import "Observer.h"
#import "TestOTWApp.h"
#import <XCTest/XCTest.h>

@interface TestFirebaseAuthUI : XCTestCase
{
    OTWApp *_app;
    WOContext *_ctx;
    Session *_s;
    FirebaseAuthUI *_authUI;
}
@end

@implementation TestFirebaseAuthUI

- (WOContext *)dummyContext {
    WORequest *req = [[WORequest alloc] initWithMethod:@"GET"
                                               uri:@"/"
                                           httpVersion:@"HTTP/1.1"
                                               headers:nil
                                               content:nil
                                              userInfo:nil];
    return [[[WOContext alloc] initWithRequest:req] autorelease];
}

- (void)setUp {
    _app = [[TestOTWApp alloc] init];
    _ctx = [[self dummyContext] retain];
    _s = (Session *)[_ctx session];
    _authUI = [[FirebaseAuthUI alloc] initWithContext:_ctx];
}

- (void)tearDown {
    [_authUI release]; _authUI = nil;
    [_ctx release]; _ctx = nil;
    [_app release]; _app = nil;
}

- (void)testHasUserNoUser {
    XCTAssertFalse([_authUI hasUser]);
}

- (void)testHasUserWithUser {
    Observer *user = [[[Observer alloc] init] autorelease];
    [_s setUser:user];
    XCTAssertTrue([_authUI hasUser]);
}

@end
