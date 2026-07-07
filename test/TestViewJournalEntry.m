// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestViewJournalEntry.m - Tests for the ViewJournalEntry component.
// Copyright (C) 2026 Graham Lee

#import "ViewJournalEntry.h"
#import "Session.h"
#import "JournalEntry.h"
#import "Observation.h"
#import "ObservationLocation.h"
#import "PhotoStorageMover.h"
#import "OTWApp.h"
#import <EOControl/EOControl.h>
#import <XCTest/XCTest.h>

@interface TestViewJournalEntry : XCTestCase
{
    OTWApp *_app;
    WOContext *_ctx;
    ViewJournalEntry *_viewPage;
}
@end

@implementation TestViewJournalEntry

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
    _viewPage = [[ViewJournalEntry alloc] initWithContext:_ctx];
}

- (void)tearDown {
    [_viewPage release]; _viewPage = nil;
    [_ctx release]; _ctx = nil;
    [_app release]; _app = nil;
}

- (void)testSetCurrentEntryPopulatesEditedFields {
    JournalEntry *entry = [[[JournalEntry alloc] init] autorelease];
    [entry setTitle:@"Test Title"];
    [entry setReflections:@"Test Reflections"];
    
    [_viewPage setCurrentEntry:entry];
    
    XCTAssertEqualObjects([_viewPage editedTitle], @"Test Title");
    XCTAssertEqualObjects([_viewPage editedReflections], @"Test Reflections");
}

- (void)testHasLocations {
    JournalEntry *entry = [[[JournalEntry alloc] init] autorelease];
    NSMutableArray *obsArray = [NSMutableArray array];
    
    Observation *noLocObs = [[[Observation alloc] init] autorelease];
    [obsArray addObject:noLocObs];
    
    [entry setObservations:obsArray];
    [_viewPage setCurrentEntry:entry];
    
    XCTAssertFalse([_viewPage hasLocations]);
    
    Observation *locObs = [[[Observation alloc] init] autorelease];
    ObservationLocation *loc = [[[ObservationLocation alloc] init] autorelease];
    [loc setLatitude:[NSNumber numberWithDouble:1.0]];
    [loc setLongitude:[NSNumber numberWithDouble:2.0]];
    [locObs setLocation:loc];
    
    [obsArray addObject:locObs];
    [entry setObservations:obsArray];
    [_viewPage setCurrentEntry:entry];
    
    XCTAssertTrue([_viewPage hasLocations]);
}



- (void)testBackToJournal {
    id nextPage = [_viewPage backToJournal];
    XCTAssertEqualObjects([nextPage class], NSClassFromString(@"BrowseJournal"));
}

- (void)testDeleteEntryReturnsToBrowseJournal {
    // Basic test to ensure it returns the right component.
    Session *s = (Session *)[_ctx session];
    EOEditingContext *ec = [s editingContext];
    
    JournalEntry *entry = [ec createAndInsertInstanceOfEntityNamed:@"JournalEntry"];
    [entry setJournalEntryId:@"test-id"];
    
    [_viewPage setCurrentEntry:entry];
    id nextPage = [_viewPage deleteEntry];
    
    XCTAssertEqualObjects([nextPage class], NSClassFromString(@"BrowseJournal"));
    XCTAssertNil([_viewPage currentEntry]);
}

- (void)testSaveChangesUpdatesEntry {
    JournalEntry *entry = [[[JournalEntry alloc] init] autorelease];
    [entry setTitle:@"Old Title"];
    [entry setReflections:@"Old Reflections"];
    
    [_viewPage setCurrentEntry:entry];
    [_viewPage setEditedTitle:@"New Title"];
    [_viewPage setEditedReflections:@"New Reflections"];
    
    // We expect an error because the entry isn't in an EC that can save properly without DB
    // but the fields should still be updated on the entry before saveChanges fails.
    [_viewPage saveChanges];
    
    XCTAssertEqualObjects([entry title], @"New Title");
    XCTAssertEqualObjects([entry reflections], @"New Reflections");
}

@end
