// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestOTWStyleSheet.m - Tests for the OTWStyleSheet component.
// Copyright (C) 2026 Graham Lee
//

#import "OTWStyleSheet.h"
#import "TestOTWApp.h"
#import <WebObjects/WebObjects.h>
#import <XCTest/XCTest.h>

@interface GSWApplication (Mock)
- (NSString *)urlForResourceNamed:(NSString *)name
                     inFramework:(NSString *)framework
                       languages:(NSArray *)languages
                         request:(GSWRequest *)request;
@end

@implementation GSWApplication (Mock)
- (NSString *)urlForResourceNamed:(NSString *)name
                     inFramework:(NSString *)framework
                       languages:(NSArray *)languages
                         request:(GSWRequest *)request {
    return [NSString stringWithFormat:@"/mock-resource/%@", name];
}
@end

@interface CapturedResponse : WOResponse {
    NSMutableString *_output;
}
- (void)appendContentString:(NSString *)string;
- (NSString *)capturedOutput;
@end

@implementation CapturedResponse
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

@interface TestOTWStyleSheet : XCTestCase
@end

@implementation TestOTWStyleSheet

- (WOContext *)dummyContext {
    OTWApp *app = (OTWApp *)[WOApplication application];
    if (app == nil) {
        app = [[TestOTWApp alloc] init];
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

- (void)testOTWStyleSheetRendering {
    WOContext *ctx = [self dummyContext];
    CapturedResponse *resp = [[CapturedResponse alloc] init];
    
    OTWStyleSheet *style = [[OTWStyleSheet alloc] initWithContext:ctx];
    [style setStylesheetName:@"test.css"];
    
    [style appendToResponse:resp inContext:ctx];
    
    NSString *output = [resp capturedOutput];
    NSString *expectedStart = @"<link rel=\"stylesheet\" href=\"/mock-resource/test.css\" type=\"text/css\" />";
    
    XCTAssertEqualObjects(output, expectedStart);
    
    [style release];
    [resp release];
    [ctx release];
}

@end
