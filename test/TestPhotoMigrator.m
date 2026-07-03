// SPDX-License-Identifier: AGPL-3.0-or-later
//
// TestPhotoMigrator.m - Tests for the PhotoMigrator class
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
//
// No Postgres in CI, so the full copy+DB-update+delete success path isn't
// testable here (faulting any globalID fails without a real DB) - covered by
// manual staging verification instead (onthewing-czs.14). What IS testable:
// delete must never fire unless both copy and the DB update succeed first.

#import "PhotoMigrator.h"
#import "PhotoStorageMover.h"
#import <EOControl/EOControl.h>
#import <XCTest/XCTest.h>

// Returns the same canned status for every request.
@interface UniformFakeTransport : NSObject <PhotoStorageMoverTransport>
{
    NSInteger _status;
    NSUInteger _callCount;
}
- (id)initWithStatus:(NSInteger)status;
@property (nonatomic, readonly) NSUInteger callCount;
@end

@implementation UniformFakeTransport

@synthesize callCount = _callCount;

- (id)initWithStatus:(NSInteger)status {
    self = [super init];
    if (self) {
        _status = status;
    }
    return self;
}

- (NSData *)sendRequest:(NSURLRequest *)request
                response:(NSURLResponse **)response
                   error:(NSError **)error {
    _callCount++;
    if (response) {
        *response = [[[NSHTTPURLResponse alloc] initWithURL:[request URL]
                                                    statusCode:_status
                                                   HTTPVersion:@"HTTP/1.1"
                                                  headerFields:nil] autorelease];
    }
    return [@"data" dataUsingEncoding:NSUTF8StringEncoding];
}

@end

@interface TestPhotoMigrator : XCTestCase
@end

@implementation TestPhotoMigrator

- (void)testMigrationStopsAfterCopyFailure {
    UniformFakeTransport *transport = [[[UniformFakeTransport alloc] initWithStatus:500] autorelease];
    PhotoStorageMover *mover = [[[PhotoStorageMover alloc] initWithBucket:@"test-bucket"
                                                                 apiBaseURL:@"http://emulator.local:9199"
                                                      serviceAccountKeyPath:nil
                                                                  transport:transport] autorelease];
    PhotoMigrator *migrator = [[[PhotoMigrator alloc] initWithMover:mover] autorelease];

    NSDictionary *info = @{
        PhotoMigratorGlobalIDKey: [EOTemporaryGlobalID temporaryGlobalID],
        PhotoMigratorTempPathKey: @"temp/uid/photo.jpg",
        PhotoMigratorPermanentPathKey: @"journal/uid/entry1/photo.jpg"
    };
    [migrator migratePhotoWithInfo:info];

    // Only the copy's GET should have fired - no upload, no delete.
    XCTAssertEqual([transport callCount], (NSUInteger)1);
}

- (void)testMigrationDoesNotDeleteWhenDatabaseUpdateFails {
    // Copy succeeds (GET + upload both return 200); the DB update inside
    // PhotoMigrator then fails because there's no real Postgres in CI to
    // fault the (fake) global ID against - delete must not fire.
    UniformFakeTransport *transport = [[[UniformFakeTransport alloc] initWithStatus:200] autorelease];
    PhotoStorageMover *mover = [[[PhotoStorageMover alloc] initWithBucket:@"test-bucket"
                                                                 apiBaseURL:@"http://emulator.local:9199"
                                                      serviceAccountKeyPath:nil
                                                                  transport:transport] autorelease];
    PhotoMigrator *migrator = [[[PhotoMigrator alloc] initWithMover:mover] autorelease];

    NSDictionary *info = @{
        PhotoMigratorGlobalIDKey: [EOTemporaryGlobalID temporaryGlobalID],
        PhotoMigratorTempPathKey: @"temp/uid/photo.jpg",
        PhotoMigratorPermanentPathKey: @"journal/uid/entry1/photo.jpg"
    };
    [migrator migratePhotoWithInfo:info];

    // 2 calls for copy (GET+upload); a 3rd (DELETE) would appear if the DB
    // update had incorrectly been treated as successful.
    XCTAssertEqual([transport callCount], (NSUInteger)2);
}

@end
