// SPDX-License-Identifier: AGPL-3.0-or-later
//
// PhotoMigrator.m - Moves a saved Observation's photo to permanent storage.
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

#import "PhotoMigrator.h"
#import "PhotoStorageMover.h"
#import "Observation.h"
#import <EOControl/EOControl.h>

NSString * const PhotoMigratorGlobalIDKey = @"globalID";
NSString * const PhotoMigratorTempPathKey = @"tempPath";
NSString * const PhotoMigratorPermanentPathKey = @"permanentPath";

static NSString * const kDefaultPublicBaseURL = @"https://firebasestorage.googleapis.com";

// Firebase's client-facing download URL for an object, e.g.
// https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{urlencoded-path}?alt=media
// Public read on journal/ paths (see storage.rules) means no download token
// is needed here, unlike temp/ URLs the client SDK generates.
static NSString *PMDownloadURLStringForPath(NSString *path) {
    NSDictionary *env = [[NSProcessInfo processInfo] environment];
    NSString *baseURL = [env objectForKey:@"FIREBASE_STORAGE_PUBLIC_BASE_URL"];
    if (baseURL.length == 0) {
        baseURL = kDefaultPublicBaseURL;
    }
    NSString *bucket = [env objectForKey:@"GCS_BUCKET"];

    NSMutableCharacterSet *unreserved = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [unreserved addCharactersInString:@"-._~"];
    NSString *encodedPath = [path stringByAddingPercentEncodingWithAllowedCharacters:unreserved];
    [unreserved release];

    return [NSString stringWithFormat:@"%@/v0/b/%@/o/%@?alt=media", baseURL, bucket, encodedPath];
}

@implementation PhotoMigrator

- (id)initWithMover:(PhotoStorageMover *)mover {
    self = [super init];
    if (self) {
        _mover = [mover retain];
    }
    return self;
}

- (void)dealloc {
    [_mover release];
    [super dealloc];
}

- (void)migratePhotoWithInfo:(NSDictionary *)info {
    @autoreleasepool {
        EOGlobalID *globalID = [info objectForKey:PhotoMigratorGlobalIDKey];
        NSString *tempPath = [info objectForKey:PhotoMigratorTempPathKey];
        NSString *permanentPath = [info objectForKey:PhotoMigratorPermanentPathKey];

        NSError *copyError = nil;
        if (![_mover copyObjectFromPath:tempPath toPath:permanentPath error:&copyError]) {
            NSLog(@"PhotoMigrator: copy failed for %@: %@", tempPath, copyError);
            return;
        }

        EOEditingContext *ec = [[[EOEditingContext alloc] init] autorelease];
        [ec lock];
        BOOL saved = NO;
        NS_DURING {
            Observation *observation = [ec faultForGlobalID:globalID editingContext:ec];
            [observation setPhotoURLString:PMDownloadURLStringForPath(permanentPath)];
            [ec saveChanges];
            saved = YES;
        }
        NS_HANDLER {
            NSLog(@"PhotoMigrator: DB update failed for %@: %@", tempPath, localException);
        }
        NS_ENDHANDLER;
        [ec unlock];

        if (!saved) {
            return;
        }

        NSError *deleteError = nil;
        if (![_mover deleteObjectAtPath:tempPath error:&deleteError]) {
            NSLog(@"PhotoMigrator: cleanup delete failed for %@: %@", tempPath, deleteError);
        }
    }
}

@end
