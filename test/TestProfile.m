// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestProfile.m - Tests for the Profile component.
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

#import "Profile.h"
#import "Session.h"
#import "Observer.h"
#import "JournalEntry.h"
#import "Observation.h"
#import "PhotoStorageMover.h"
#import "TestOTWApp.h"
#import <EOControl/EOControl.h>
#import <EOAccess/EOAccess.h>
#import <XCTest/XCTest.h>

// Records DELETE requests instead of performing them, so deleteAccount tests
// can count how many photo deletes were attempted.
@interface ProfileRecordingDeleteTransport : NSObject <PhotoStorageMoverTransport>
{
    NSMutableArray *_deletedURLs;
}
@property (nonatomic, readonly) NSArray *deletedURLs;
@end

@implementation ProfileRecordingDeleteTransport

- (id)init {
    self = [super init];
    if (self) {
        _deletedURLs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_deletedURLs release];
    [super dealloc];
}

- (NSArray *)deletedURLs {
    return _deletedURLs;
}

- (NSData *)sendRequest:(NSURLRequest *)request
                response:(NSURLResponse **)response
                   error:(NSError **)error {
    if ([[request HTTPMethod] isEqualToString:@"DELETE"]) {
        [_deletedURLs addObject:[request URL]];
    }
    if (response) {
        *response = [[[NSHTTPURLResponse alloc] initWithURL:[request URL]
                                                    statusCode:200
                                                   HTTPVersion:@"HTTP/1.1"
                                                  headerFields:nil] autorelease];
    }
    return [NSData data];
}

@end

@interface TestProfile : XCTestCase
{
    OTWApp *_app;
    WOContext *_ctx;
    Profile *_profile;
}
@end

@implementation TestProfile

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
    _profile = [[Profile alloc] initWithContext:_ctx];
}

- (void)tearDown {
    [_profile release]; _profile = nil;
    [_ctx release]; _ctx = nil;
    [_app release]; _app = nil;
}

- (void)testDeleteAccountNoOpsWhenNoUser {
    id nextPage = [_profile deleteAccount];
    XCTAssertEqualObjects([nextPage class], NSClassFromString(@"Main"));
}

- (void)testDeleteAccountRemovesUserJournalDataAndPhotosWhenDataAvailable {
    Session *s = (Session *)[_ctx session];
    EOEditingContext *ec = [s editingContext];

    NSError *error = nil;
    NSString *uid = [[NSUUID UUID] UUIDString];
    [ec lock];
    NS_DURING {
        Observer *user = [ec createAndInsertInstanceOfEntityNamed:@"Observer"];
        [user setUid:uid];
        [ec saveChanges];

        JournalEntry *entry = [ec createAndInsertInstanceOfEntityNamed:@"JournalEntry"];
        [entry setObserver:user];
        if (![user journalEntries]) { [user setJournalEntries:[NSMutableArray array]]; }
        [[user journalEntries] addObject:entry];

        Observation *o1 = [ec createAndInsertInstanceOfEntityNamed:@"Observation"];
        [o1 setJournalEntry:entry];
        if (![entry observations]) { [entry setObservations:[NSMutableArray array]]; }
        [[entry observations] addObject:o1];
        [o1 setObserver:[entry observer]];
        if (![[entry observer] observations]) { [[entry observer] setObservations:[NSMutableArray array]]; }
        [[[entry observer] observations] addObject:o1];
        [o1 setCaptureDate:[NSDate date]];
        [o1 setPhotoURLString:@"https://firebasestorage.googleapis.com/v0/b/bucket/o/journal%2Fabc%2Fentry%2Fphoto1.jpg?alt=media"];

        Observation *o2 = [ec createAndInsertInstanceOfEntityNamed:@"Observation"];
        [o2 setJournalEntry:entry];
        if (![entry observations]) { [entry setObservations:[NSMutableArray array]]; }
        [[entry observations] addObject:o2];
        [o2 setObserver:[entry observer]];
        if (![[entry observer] observations]) { [[entry observer] setObservations:[NSMutableArray array]]; }
        [[[entry observer] observations] addObject:o2];
        [o2 setCaptureDate:[NSDate date]];
        [o2 setPhotoURLString:@"https://firebasestorage.googleapis.com/v0/b/bucket/o/journal%2Fabc%2Fentry%2Fphoto2.jpg?alt=media"];

        [ec saveChanges];

        [s setUser:user];
    }
    NS_HANDLER {
        NSLog(@"testDeleteAccountRemovesUserJournalDataAndPhotosWhenDataAvailable: no DB available to set up fixtures: %@", localException);
        error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    }
    NS_ENDHANDLER;
    [ec unlock];

    if (error != nil) {
        // No DB in this environment - nothing meaningful to assert.
        return;
    }

    ProfileRecordingDeleteTransport *transport = [[[ProfileRecordingDeleteTransport alloc] init] autorelease];
    PhotoStorageMover *mover = [[[PhotoStorageMover alloc] initWithBucket:@"test-bucket"
                                                                 apiBaseURL:@"http://emulator.local:9199"
                                                      serviceAccountKeyPath:nil
                                                                  transport:transport] autorelease];
    [_profile setPhotoStorageMover:mover];

    id nextPage = [_profile deleteAccount];

    XCTAssertEqualObjects([nextPage class], NSClassFromString(@"Main"));
    XCTAssertNil([s user]);
    XCTAssertEqual([[transport deletedURLs] count], (NSUInteger)2);

    // Direct qualifier fetch rather than Observer.journalEntries: the
    // deleted user's Observer instance is gone, so there's no EC-registered
    // object left to hang the relationship off; this checks DB state instead.
    EOQualifier *qualifier = [EOQualifier qualifierWithQualifierFormat:@"observerForeignKey = %@", uid];
    EOFetchSpecification *fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:@"JournalEntry"
                                                                                     qualifier:qualifier
                                                                                 sortOrderings:nil];
    XCTAssertEqual([[ec objectsWithFetchSpecification:fetchSpec] count], (NSUInteger)0);
}

@end
