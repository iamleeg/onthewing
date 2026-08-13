// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestErrorPage.m - Tests for the ErrorPage component
// Copyright (C) 2026 Graham Lee
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

#import "ErrorPage.h"
#import <XCTest/XCTest.h>

@interface TestErrorPage : XCTestCase
@end

@implementation TestErrorPage

- (void)testCorrelationIdCanBeSetAndRetrieved {
    WORequest *req = [[WORequest alloc] initWithMethod:@"GET" uri:@"/" httpVersion:@"HTTP/1.1" headers:nil content:nil userInfo:nil];
    WOContext *ctx = [[WOContext alloc] initWithRequest:req];
    ErrorPage *page = [[ErrorPage alloc] initWithContext:ctx];
    NSString *testId = @"12345-ABCDE";
    
    [page setCorrelationId:testId];
    XCTAssertEqualObjects([page correlationId], testId);
    
    [page release];
    [ctx release];
    [req release];
}

@end
