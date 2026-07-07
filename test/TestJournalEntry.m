// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestJournalEntry.m - Tests for the JournalEntry class
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

#import "JournalEntry.h"
#import "Observer.h"
#import "Observation.h"
#import "OTWApp.h"
#import <EOControl/EOControl.h>
#import <EOAccess/EOAccess.h>
#import <XCTest/XCTest.h>

@interface TestJournalEntry : XCTestCase
@end

@implementation TestJournalEntry

- (void)testDatePropertySetting {
    JournalEntry *entry = [[JournalEntry alloc] init];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:10000];
    
    Observation *obs = [[Observation alloc] init];
    [obs setCaptureDate:date];
    [entry setObservations:(NSMutableArray *)@[obs]];
    [obs release];

    XCTAssertEqualObjects([entry date], date);
    [entry release];
}

- (void)testObserverPropertySetting {
    JournalEntry *entry = [[JournalEntry alloc] init];
    Observer *observer = [[Observer alloc] initWithUid:@"uid-1"
                                                   name:@"Jane Doe"
                                                  email:@"jane@example.com"
                                              avatarUrl:nil
                                                  token:@"token"];

    [entry setObserver:observer];

    XCTAssertEqualObjects([entry observer], observer);
    [entry release];
    [observer release];
}

- (void)testObservationsPropertySetting {
    JournalEntry *entry = [[JournalEntry alloc] init];
    NSMutableArray *observations = [NSMutableArray array];

    [entry setObservations:observations];

    XCTAssertEqualObjects([entry observations], observations);
    XCTAssertEqual([[entry observations] count], (NSUInteger)0);
    [entry release];
}

- (void)testTitlePropertySetting {
    JournalEntry *entry = [[JournalEntry alloc] init];
    NSString *title = @"Morning Walk";

    [entry setTitle:title];

    XCTAssertEqualObjects([entry title], title);
    [entry release];
}

- (void)testReflectionsPropertySetting {
    JournalEntry *entry = [[JournalEntry alloc] init];
    NSString *reflections = @"Saw a heron today.";

    [entry setReflections:reflections];

    XCTAssertEqualObjects([entry reflections], reflections);
    [entry release];
}

- (void)testValidateForSaveRequiresObservation {
    JournalEntry *entry = [[JournalEntry alloc] init];
    
    // No observations set
    NSException *ex1 = [entry validateForSave];
    XCTAssertNotNil(ex1);
    XCTAssertEqualObjects([ex1 name], @"EOValidationException");
    
    // Empty observations array
    [entry setObservations:[NSMutableArray array]];
    NSException *ex2 = [entry validateForSave];
    XCTAssertNotNil(ex2);
    
    // One observation
    Observation *obs = [[Observation alloc] init];
    [entry setObservations:(NSMutableArray *)@[obs]];
    NSException *ex3 = [entry validateForSave];
    XCTAssertNil(ex3);
    
    [obs release];
    [entry release];
}

// Diagnostic for the libs-gdl2 array-fault bug ("Resolve a circular loop in
// faulting to-many relationships", vendored-fixes branch): fetches an
// Observer by uid in a fresh editing context (so its relationships start as
// unfired faults, matching what production actually hits), then follows
// Observer.journalEntries and JournalEntry.observations directly rather than
// through an explicit EOFetchSpecification workaround. Skips its assertions
// (but not the test) when no DB is reachable, matching the rest of the suite.
- (void)testToManyRelationshipsFaultCorrectlyAfterFreshFetch {
    OTWApp *app = [[OTWApp alloc] init];
    EOEditingContext *ec1 = [[[EOEditingContext alloc] init] autorelease];

    NSString *uid = [[NSUUID UUID] UUIDString];
    NSError *setupError = nil;
    [ec1 lock];
    NS_DURING {
        Observer *user = [ec1 createAndInsertInstanceOfEntityNamed:@"Observer"];
        [user setUid:uid];

        JournalEntry *entry = [ec1 createAndInsertInstanceOfEntityNamed:@"JournalEntry"];
        [entry setObserver:user];

        Observation *observation = [ec1 createAndInsertInstanceOfEntityNamed:@"Observation"];
        [entry addObject:observation toBothSidesOfRelationshipWithKey:@"observations"];
        [observation setCaptureDate:[NSDate date]];

        [ec1 saveChanges];
    }
    NS_HANDLER {
        NSLog(@"testToManyRelationshipsFaultCorrectlyAfterFreshFetch: no DB available to set up fixtures: %@", localException);
        setupError = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    }
    NS_ENDHANDLER;
    [ec1 unlock];

    if (setupError != nil) {
        [app release];
        return;
    }

    EOEditingContext *ec2 = [[[EOEditingContext alloc] init] autorelease];
    NSInteger journalEntryCount = -1;
    NSInteger observationCount = -1;
    NSException *fetchException = nil;
    [ec2 lock];
    NS_DURING {
        EOQualifier *qualifier = [EOQualifier qualifierWithQualifierFormat:@"uid = %@", uid];
        EOFetchSpecification *fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:@"Observer"
                                                                                         qualifier:qualifier
                                                                                     sortOrderings:nil];
        Observer *fetchedUser = [[ec2 objectsWithFetchSpecification:fetchSpec] firstObject];
        NSArray *journalEntries = [fetchedUser journalEntries];
        journalEntryCount = (NSInteger)[journalEntries count];
        JournalEntry *fetchedEntry = [journalEntries firstObject];
        observationCount = (NSInteger)[[fetchedEntry observations] count];
    }
    NS_HANDLER {
        fetchException = localException;
    }
    NS_ENDHANDLER;
    [ec2 unlock];

    XCTAssertNil(fetchException, @"following the relationships raised: %@", fetchException);
    XCTAssertEqual(journalEntryCount, (NSInteger)1);
    XCTAssertEqual(observationCount, (NSInteger)1);

    [app release];
}

@end
