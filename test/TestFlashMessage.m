// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestFlashMessage.m - Tests for the FlashMessage component
// Copyright (C) 2026 Graham Lee
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

#import "FlashMessage.h"
#import "OTWFlashMessage.h"
#import "TestOTWApp.h"
#import <XCTest/XCTest.h>
#import <WebObjects/WebObjects.h>

@interface FlashMessage (TestExposure)
- (void)setMessage:(OTWFlashMessage *)msg;
@end

@implementation FlashMessage (TestExposure)
- (void)setMessage:(OTWFlashMessage *)msg {
    [_message autorelease];
    _message = [msg retain];
}
@end

@interface TestFlashMessage : XCTestCase {
    OTWApp *_app;
    WORequest *_req;
    WOContext *_ctx;
}
@end

@implementation TestFlashMessage

- (void)setUp {
  _app = [[TestOTWApp alloc] init];
  _req = [[WORequest alloc] initWithMethod:@"GET"
                                       uri:@"/"
                               httpVersion:@"HTTP/1.1"
                                   headers:nil
                                   content:nil
                                  userInfo:nil];
  _ctx = [[WOContext alloc] initWithRequest:_req];
}

- (void)tearDown {
  [_ctx release]; _ctx = nil;
  [_req release]; _req = nil;
  [_app release]; _app = nil;
}

- (void)testFlashMessageNoMessage {
    FlashMessage *component = [[FlashMessage alloc] initWithContext:_ctx];
    
    XCTAssertFalse([component hasMessage]);
    XCTAssertEqualObjects([component messageClass], @"");
    
    [component release];
}

- (void)testFlashMessageErrorClass {
    FlashMessage *component = [[FlashMessage alloc] initWithContext:_ctx];
    OTWFlashMessage *msg = [[OTWFlashMessage alloc] initWithStringValue:@"Error!" severityLevel:OTWFlashMessageSeverityError];
    [component setMessage:msg];
    [msg release];
    
    XCTAssertTrue([component hasMessage]);
    XCTAssertEqualObjects([component messageClass], @"flash-message flash-error");
    XCTAssertEqualObjects([component messageText], @"Error!");
    
    [component release];
}

- (void)testFlashMessageSuccessClass {
    FlashMessage *component = [[FlashMessage alloc] initWithContext:_ctx];
    OTWFlashMessage *msg = [[OTWFlashMessage alloc] initWithStringValue:@"Yay!" severityLevel:OTWFlashMessageSeveritySuccess];
    [component setMessage:msg];
    [msg release];
    
    XCTAssertTrue([component hasMessage]);
    XCTAssertEqualObjects([component messageClass], @"flash-message flash-success");
    XCTAssertEqualObjects([component messageText], @"Yay!");
    
    [component release];
}

- (void)testFlashMessageInfoClass {
    FlashMessage *component = [[FlashMessage alloc] initWithContext:_ctx];
    OTWFlashMessage *msg = [[OTWFlashMessage alloc] initWithStringValue:@"Info." severityLevel:OTWFlashMessageSeverityInfo];
    [component setMessage:msg];
    [msg release];
    
    XCTAssertTrue([component hasMessage]);
    XCTAssertEqualObjects([component messageClass], @"flash-message flash-info");
    XCTAssertEqualObjects([component messageText], @"Info.");
    
    [component release];
}

@end
