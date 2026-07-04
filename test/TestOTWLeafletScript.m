// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestOTWLeafletScript.m - Tests for the OTWLeafletScript component.
// Copyright (C) 2026 Graham Lee
//

#import "OTWLeafletScript.h"
#import "OTWApp.h"
#import <WebObjects/WebObjects.h>
#import <XCTest/XCTest.h>

@interface CapturedLeafletResponse : WOResponse {
    NSMutableString *_output;
}
- (void)appendContentString:(NSString *)string;
- (NSString *)capturedOutput;
@end

@implementation CapturedLeafletResponse
- (instancetype)init {
    self = [super init];
    if (self) {
        _output = [[NSMutableString alloc] init];
    }
    return self;
}
- (void)appendContentString:(NSString *)string {
    [_output appendString:string];
}
- (NSString *)capturedOutput {
    return _output;
}
@end

@interface TestOTWLeafletScript : XCTestCase
@end

@implementation TestOTWLeafletScript

- (WOContext *)dummyContext {
    OTWApp *app = (OTWApp *)[WOApplication application];
    if (app == nil) {
        app = [[OTWApp alloc] init];
        [WOApplication _setApplication:app];
    }
    WORequest *req = [[WORequest alloc] initWithMethod:@"GET"
                                               uri:@"/"
                                           httpVersion:@"HTTP/1.1"
                                               headers:nil
                                               content:nil
                                              userInfo:nil];
    return [[WOContext alloc] initWithRequest:req];
}

- (void)testOTWLeafletScriptRendersCDNLinkAndScript {
    WOContext *ctx = [self dummyContext];
    CapturedLeafletResponse *resp = [[CapturedLeafletResponse alloc] init];

    OTWLeafletScript *leaflet = [[OTWLeafletScript alloc] initWithContext:ctx];
    [leaflet appendToResponse:resp inContext:ctx];

    NSString *output = [resp capturedOutput];

    XCTAssertTrue([output rangeOfString:@"https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"].location != NSNotFound);
    XCTAssertTrue([output rangeOfString:@"https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"].location != NSNotFound);
    XCTAssertTrue([output rangeOfString:@"integrity=\"sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=\""].location != NSNotFound);
    XCTAssertTrue([output rangeOfString:@"integrity=\"sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=\""].location != NSNotFound);

    [leaflet release];
    [resp release];
    [ctx release];
}

@end
