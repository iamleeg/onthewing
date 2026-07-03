// SPDX-License-Identifier: AGPL-3.0-or-later
//
// PhotoMigrator.h - Moves a saved Observation's photo to permanent storage.
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
// Runs synchronously on whatever thread calls it - callers on a request
// thread must use +[NSThread detachNewThreadSelector:toTarget:withObject:]
// with -migratePhotoWithInfo: (no blocks/GCD available in this toolchain,
// see PhotoStorageMover.h). Kept separate from PhotoStorageMover so that
// class stays a plain GCS client with no EOF/domain knowledge.

#import <Foundation/Foundation.h>

@class PhotoStorageMover;

extern NSString * const PhotoMigratorGlobalIDKey;      // EOGlobalID of the Observation
extern NSString * const PhotoMigratorTempPathKey;      // NSString, source GCS object path
extern NSString * const PhotoMigratorPermanentPathKey; // NSString, destination GCS object path

@interface PhotoMigrator : NSObject
{
    PhotoStorageMover *_mover;
}

- (id)initWithMover:(PhotoStorageMover *)mover;

/// Moves the photo from the temporary path to the permanent path, and updates the observation.
/// The move is implemented as a copy, followed by deleting the temporary photo, then
/// updating the observation to point at the permanent location.
/// - Parameters:
///   - info: A dictionary containing the three keys defined above,
- (void)migratePhotoWithInfo:(NSDictionary *)info;

@end
