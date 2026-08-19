// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestPresentationService.m
// Copyright (C) 2026 Graham Lee

#import <XCTest/XCTest.h>
#import "PresentationService.h"
#import "PresentationView.h"
#import "Observer.h"
#import "JournalEntry.h"
#import "Observation.h"
#import "PublishedPresentation.h"
#import "TestOTWApp.h"
#import <EOControl/EOControl.h>

@interface TestPresentationService : XCTestCase
@end

@implementation TestPresentationService

- (void)testPublishPresentationFailsForFreeTier {
    OTWApp *app = [[TestOTWApp alloc] init];
    EOEditingContext *ec = [[[EOEditingContext alloc] init] autorelease];
    PresentationService *service = [[[PresentationService alloc] initWithEditingContext:ec] autorelease];
    
    NSString *url = nil;
    [ec lock];
    NS_DURING {
        Observer *obs = [ec createAndInsertInstanceOfEntityNamed:@"Observer"];
        NSString *obsId = [[NSUUID UUID] UUIDString];
        [obs setUid:obsId];
        [obs setIsPremium:@0]; // Free tier
        
        JournalEntry *entry = [ec createAndInsertInstanceOfEntityNamed:@"JournalEntry"];
        NSString *entryId = [[NSUUID UUID] UUIDString];
        [entry setJournalEntryId:entryId];
        [entry setObserver:obs];
        Observation *obsrv = [ec createAndInsertInstanceOfEntityNamed:@"Observation"];
        [obsrv setObserver:obs];
        [obsrv setObservationId:[[NSUUID UUID] UUIDString]];
        [entry addObject:obsrv toBothSidesOfRelationshipWithKey:@"observations"];
        NSLog(@"BEFORE SAVE: obs.isPremium = %@", [obs isPremium]);

        [ec saveChanges];
        
        url = [service publishPresentationForEntryId:entryId observerId:obsId];
    }
    NS_HANDLER { NSLog(@"Exception in test: %@ userInfo: %@", localException, [localException userInfo]); }
    NS_ENDHANDLER;
    [ec unlock];
    
    XCTAssertNil(url, @"Free tier should not be able to publish");
    [app release];
}

- (void)testPublishPresentationSucceedsForPremium {
    OTWApp *app = [[TestOTWApp alloc] init];
    EOEditingContext *ec = [[[EOEditingContext alloc] init] autorelease];
    PresentationService *service = [[[PresentationService alloc] initWithEditingContext:ec] autorelease];
    
    NSString *url = nil;
    [ec lock];
    NS_DURING {
        Observer *obs = [ec createAndInsertInstanceOfEntityNamed:@"Observer"];
        NSString *obsId = [[NSUUID UUID] UUIDString];
        [obs setUid:obsId];
        [obs setIsPremium:[NSNumber numberWithInt:1]];
        
        JournalEntry *entry = [ec createAndInsertInstanceOfEntityNamed:@"JournalEntry"];
        NSString *entryId = [[NSUUID UUID] UUIDString];
        [entry setJournalEntryId:entryId];
        [entry setObserver:obs];
        Observation *obsrv = [ec createAndInsertInstanceOfEntityNamed:@"Observation"];
        [obsrv setObserver:obs];
        [obsrv setObservationId:[[NSUUID UUID] UUIDString]];
        [entry addObject:obsrv toBothSidesOfRelationshipWithKey:@"observations"];
        NSLog(@"BEFORE SAVE: obs.isPremium = %@", [obs isPremium]);

        [ec saveChanges];
        
        url = [service publishPresentationForEntryId:entryId observerId:obsId];
    }
    NS_HANDLER { NSLog(@"Exception in test: %@ userInfo: %@", localException, [localException userInfo]); }
    NS_ENDHANDLER;
    [ec unlock];
    
    XCTAssertNotNil(url, @"Premium tier should be able to publish");
    XCTAssertTrue([url length] > 0);
    [app release];
}

- (void)testPreviewPresentationReturnsTruncatedAndBlurred {
    OTWApp *app = [[TestOTWApp alloc] init];
    EOEditingContext *ec = [[[EOEditingContext alloc] init] autorelease];
    PresentationService *service = [[[PresentationService alloc] initWithEditingContext:ec] autorelease];
    
    PresentationView *view = nil;
    [ec lock];
    NS_DURING {
        Observer *obs = [ec createAndInsertInstanceOfEntityNamed:@"Observer"];
        NSString *obsId = [[NSUUID UUID] UUIDString];
        [obs setUid:obsId];
        
        JournalEntry *entry = [ec createAndInsertInstanceOfEntityNamed:@"JournalEntry"];
        NSString *entryId = [[NSUUID UUID] UUIDString];
        [entry setJournalEntryId:entryId];
        [entry setObserver:obs];
        Observation *obsrv = [ec createAndInsertInstanceOfEntityNamed:@"Observation"];
        [obsrv setObserver:obs];
        [obsrv setObservationId:[[NSUUID UUID] UUIDString]];
        [entry addObject:obsrv toBothSidesOfRelationshipWithKey:@"observations"];
        NSLog(@"BEFORE SAVE: obs.isPremium = %@", [obs isPremium]);

        [ec saveChanges];
        
        view = [service previewPresentationForEntryId:entryId observerId:obsId];
    }
    NS_HANDLER { NSLog(@"Exception in test: %@ userInfo: %@", localException, [localException userInfo]); }
    NS_ENDHANDLER;
    [ec unlock];
    
    XCTAssertNotNil(view);
    XCTAssertTrue([view isTruncatedAndBlurred], @"Preview must be truncated and blurred");
    XCTAssertFalse([view hasPrintSupport], @"Preview should not have print support");
    [app release];
}

- (void)testGetPresentationReturnsValidViewWithoutCompass {
    OTWApp *app = [[TestOTWApp alloc] init];
    EOEditingContext *ec = [[[EOEditingContext alloc] init] autorelease];
    PresentationService *service = [[[PresentationService alloc] initWithEditingContext:ec] autorelease];
    
    PresentationView *view = nil;
    [ec lock];
    NS_DURING {
        Observer *obs = [ec createAndInsertInstanceOfEntityNamed:@"Observer"];
        NSString *obsId = [[NSUUID UUID] UUIDString];
        [obs setUid:obsId];
        [obs setIsPremium:[NSNumber numberWithInt:1]];
        
        JournalEntry *entry = [ec createAndInsertInstanceOfEntityNamed:@"JournalEntry"];
        NSString *entryId = [[NSUUID UUID] UUIDString];
        [entry setJournalEntryId:entryId];
        [entry setObserver:obs];
        Observation *obsrv = [ec createAndInsertInstanceOfEntityNamed:@"Observation"];
        [obsrv setObserver:obs];
        [obsrv setObservationId:[[NSUUID UUID] UUIDString]];
        [entry addObject:obsrv toBothSidesOfRelationshipWithKey:@"observations"];
        NSLog(@"BEFORE SAVE: obs.isPremium = %@", [obs isPremium]);

        [ec saveChanges];
        
        NSString *url = [service publishPresentationForEntryId:entryId observerId:obsId];
        view = [service getPresentationForUrlId:url];
    }
    NS_HANDLER { NSLog(@"Exception in test: %@ userInfo: %@", localException, [localException userInfo]); }
    NS_ENDHANDLER;
    [ec unlock];
    
    XCTAssertNotNil(view);
    XCTAssertFalse([view isTruncatedAndBlurred], @"Live view must not be truncated");
    XCTAssertTrue([view hasPrintSupport], @"Live view must have print support");
    [app release];
}

- (void)testUnpublishPresentationDeletesMapping {
    OTWApp *app = [[TestOTWApp alloc] init];
    EOEditingContext *ec = [[[EOEditingContext alloc] init] autorelease];
    PresentationService *service = [[[PresentationService alloc] initWithEditingContext:ec] autorelease];
    
    PresentationView *view = (id)[NSNull null]; // placeholder
    [ec lock];
    NS_DURING {
        Observer *obs = [ec createAndInsertInstanceOfEntityNamed:@"Observer"];
        NSString *obsId = [[NSUUID UUID] UUIDString];
        [obs setUid:obsId];
        [obs setIsPremium:[NSNumber numberWithInt:1]];
        
        JournalEntry *entry = [ec createAndInsertInstanceOfEntityNamed:@"JournalEntry"];
        NSString *entryId = [[NSUUID UUID] UUIDString];
        [entry setJournalEntryId:entryId];
        [entry setObserver:obs];
        Observation *obsrv = [ec createAndInsertInstanceOfEntityNamed:@"Observation"];
        [obsrv setObserver:obs];
        [obsrv setObservationId:[[NSUUID UUID] UUIDString]];
        [entry addObject:obsrv toBothSidesOfRelationshipWithKey:@"observations"];
        NSLog(@"BEFORE SAVE: obs.isPremium = %@", [obs isPremium]);

        [ec saveChanges];
        
        NSString *url = [service publishPresentationForEntryId:entryId observerId:obsId];
        [service unpublishPresentationForEntryId:entryId];
        
        view = [service getPresentationForUrlId:url];
    }
    NS_HANDLER { NSLog(@"Exception in test: %@ userInfo: %@", localException, [localException userInfo]); }
    NS_ENDHANDLER;
    [ec unlock];
    
    XCTAssertNil(view, @"Unpublished view must return nil");
    [app release];
}

@end
