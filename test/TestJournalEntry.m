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
#import <XCTest/XCTest.h>

@interface TestJournalEntry : XCTestCase
@end

@implementation TestJournalEntry

- (void)testDatePropertySetting {
    JournalEntry *entry = [[JournalEntry alloc] init];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:10000];

    [entry setDate:date];

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

@end
