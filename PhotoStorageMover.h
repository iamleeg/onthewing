// SPDX-License-Identifier: AGPL-3.0-or-later
//
// PhotoStorageMover.h - Copies/deletes journal photos in Google Cloud Storage.
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

// PhotoStorageMover talks to the GCS JSON API (not Firebase's client-facing
// REST API) so that requests bypass Firebase Storage security rules the same
// way Admin SDK access does in production. Against the local Firebase Storage
// emulator this same API surface is served unauthenticated on the storage
// port, which is why authorization here is optional (see
// -initWithBucket:apiBaseURL:serviceAccountKeyPath:transport:): when no
// service-account key path is configured, requests are sent without a bearer
// token at all, which the emulator accepts and production GCS would reject -
// that's the intended dev/prod split, driven by GCS_API_BASE_URL /
// GCS_SERVICE_ACCOUNT_KEY_PATH / GCS_BUCKET.
//
// "Move" is deliberately NOT a single operation: copyObjectFromPath:toPath:
// only copies (the GCS objects.rewrite API this could otherwise use returns
// 501 on the Storage emulator, so copy is implemented as download+upload
// instead), and deleteObjectAtPath: is separate, so a caller can update its
// own bookkeeping (e.g. an Observation's photoURL) in between - deleting the
// source before that bookkeeping is updated would leave a reference to a
// deleted object.
//

#import <Foundation/Foundation.h>

// Mirrors +[NSURLConnection sendSynchronousRequest:returningResponse:error:]'s
// shape so the default transport is a one-line wrapper around it, and tests
// can inject a fake that returns canned responses without any networking.
@protocol PhotoStorageMoverTransport <NSObject>
- (NSData *)sendRequest:(NSURLRequest *)request
                response:(NSURLResponse **)response
                   error:(NSError **)error;
@end

@interface PhotoStorageMover : NSObject
{
    NSString *_bucket;
    NSString *_apiBaseURL;
    NSString *_serviceAccountKeyPath;
    id<PhotoStorageMoverTransport> _transport;
}

// Reads GCS_BUCKET, GCS_API_BASE_URL (defaults to https://storage.googleapis.com
// if unset), and GCS_SERVICE_ACCOUNT_KEY_PATH (optional - if unset, requests are
// made without authorization) from the process environment, and uses a real
// NSURLConnection-backed transport.
- (id)init;

// Designated initializer for tests: inject fixed config and a fake transport.
- (id)initWithBucket:(NSString *)bucket
          apiBaseURL:(NSString *)apiBaseURL
serviceAccountKeyPath:(NSString *)serviceAccountKeyPath
           transport:(id<PhotoStorageMoverTransport>)transport;

// Downloads sourcePath's bytes and uploads them to destinationPath. Does NOT
// touch sourcePath. Synchronous - don't send this message from the request/response thread.
- (BOOL)copyObjectFromPath:(NSString *)sourcePath
                      toPath:(NSString *)destinationPath
                       error:(NSError **)error;

// Deletes the object at path. Synchronous.
- (BOOL)deleteObjectAtPath:(NSString *)path
                       error:(NSError **)error;

@end
