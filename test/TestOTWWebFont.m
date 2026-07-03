// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestOTWWebFont.m - Tests for the OTWWebFont component.
// Copyright (C) 2026 Graham Lee
//

#import "OTWWebFont.h"
#import "OTWApp.h"
#import <WebObjects/WebObjects.h>
#import <XCTest/XCTest.h>

@interface CapturedFontResponse : WOResponse {
    NSMutableString *_output;
}
- (void)appendContentString:(NSString *)string;
- (NSString *)capturedOutput;
@end

@implementation CapturedFontResponse
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

@interface TestOTWWebFont : XCTestCase
@end

@implementation TestOTWWebFont

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

- (void)testOTWWebFontRendersPreconnectAndStylesheetLinks {
    WOContext *ctx = [self dummyContext];
    CapturedFontResponse *resp = [[CapturedFontResponse alloc] init];

    OTWWebFont *webFont = [[OTWWebFont alloc] initWithContext:ctx];
    [webFont appendToResponse:resp inContext:ctx];

    NSString *output = [resp capturedOutput];

    XCTAssertTrue([output rangeOfString:@"<link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">"].location != NSNotFound);
    XCTAssertTrue([output rangeOfString:@"<link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>"].location != NSNotFound);
    XCTAssertTrue([output rangeOfString:@"fonts.googleapis.com/css2"].location != NSNotFound);
    XCTAssertTrue([output rangeOfString:@"family=Fira+Mono"].location != NSNotFound);
    XCTAssertTrue([output rangeOfString:@"family=Inter"].location != NSNotFound);
    XCTAssertTrue([output rangeOfString:@"family=Lora"].location != NSNotFound);
    XCTAssertTrue([output rangeOfString:@"family=Oswald"].location != NSNotFound);

    [webFont release];
    [resp release];
    [ctx release];
}

@end
