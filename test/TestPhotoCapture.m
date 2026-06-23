// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestPhotoCapture.m - Tests for the PhotoCapture component.
// Copyright (C) 2026 Graham Lee
//

#import "PhotoCapture.h"
#import "Observation.h"
#import "Session.h"
#import "OTWApp.h"
#import <XCTest/XCTest.h>

@interface TestPhotoCapture : XCTestCase
{
  OTWApp *_app;
  WOContext *_ctx;
  PhotoCapture *_photoCapture;
}
@end

@implementation TestPhotoCapture

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
  _app = [[OTWApp alloc] init];
  _ctx = [[self dummyContext] retain];
  _photoCapture = [[PhotoCapture alloc] initWithContext:_ctx];
}

- (void)tearDown {
  [_photoCapture release]; _photoCapture = nil;
  [_ctx release]; _ctx = nil;
  [_app release]; _app = nil;
}

- (void)testUniqueElementIdsContainObservationPointer {
  Observation *o = [Observation new];
  [_photoCapture setObservation:o];

  NSString *ptrStr = [NSString stringWithFormat:@"%p", o];
  XCTAssertTrue([[_photoCapture formID] containsString:ptrStr]);
  XCTAssertTrue([[_photoCapture urlInputID] containsString:ptrStr]);
  XCTAssertTrue([[_photoCapture actionInputID] containsString:ptrStr]);
  XCTAssertTrue([[_photoCapture statusID] containsString:ptrStr]);
  XCTAssertTrue([[_photoCapture fileInputID] containsString:ptrStr]);

  [o release];
}

- (void)testLabelAndButtonTextsForNoPhoto {
  Observation *o = [Observation new];
  [_photoCapture setObservation:o];

  XCTAssertFalse([_photoCapture hasPhoto]);
  XCTAssertEqualObjects([_photoCapture labelText], @"Add photo:");
  XCTAssertEqualObjects([_photoCapture buttonText], @"Upload Photo");

  [o release];
}

- (void)testLabelAndButtonTextsForExistingPhoto {
  Observation *o = [Observation new];
  [o setPhotoURL:[NSURL URLWithString:@"http://temp/1.jpg"]];
  [_photoCapture setObservation:o];

  XCTAssertTrue([_photoCapture hasPhoto]);
  XCTAssertEqualObjects([_photoCapture labelText], @"Replace photo:");
  XCTAssertEqualObjects([_photoCapture buttonText], @"Replace Photo");

  [o release];
}

- (void)testKVCResolutionOfPhotoURL {
  Observation *o = [Observation new];
  [o setPhotoURL:[NSURL URLWithString:@"http://temp/1.jpg"]];
  [_photoCapture setObservation:o];

  id val = [_photoCapture valueForKeyPath:@"observation.photoURL.absoluteString"];
  XCTAssertEqualObjects(val, @"http://temp/1.jpg");

  [o release];
}


- (void)testSubmitPhotoUploads {
  Observation *o = [Observation new];
  [_photoCapture setObservation:o];
  [_photoCapture setPhotoURL:@"http://temp/uploaded.jpg"];
  [_photoCapture setPhotoAction:@"upload"];
  [_photoCapture setNextComponent:@"Capture"];

  id page = [_photoCapture submitPhoto];
  XCTAssertNotNil(page);
  XCTAssertEqualObjects([[o photoURL] absoluteString], @"http://temp/uploaded.jpg");

  [o release];
}

- (void)testSubmitPhotoRemoves {
  Observation *o = [Observation new];
  [o setPhotoURL:[NSURL URLWithString:@"http://temp/uploaded.jpg"]];
  [_photoCapture setObservation:o];
  [_photoCapture setPhotoAction:@"remove"];
  [_photoCapture setNextComponent:@"Capture"];

  id page = [_photoCapture submitPhoto];
  XCTAssertNotNil(page);
  XCTAssertNil([o photoURL]);

  [o release];
}

@end
