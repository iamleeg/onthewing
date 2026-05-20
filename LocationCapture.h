// SPDX-License-Identifier: AGPL-3.0-or-later
//
// LocationCapture.h - Dynamic component for capturing location and bearing.
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

#import <WebObjects/WebObjects.h>

@class ObservationLocation;

@protocol LocationUsing <NSObject>
- (void)setCapturedLocation:(ObservationLocation *)loc;
- (void)setLocationError:(NSString *)error;
@end

@interface LocationCapture : GSWComponent {
    NSString *latitude;
    NSString *longitude;
    NSString *accuracy;
    NSString *bearing;
    NSString *locationError;
    NSString *bearingError;
    NSString *nextComponent;
}

@property (nonatomic, copy) NSString *latitude;
@property (nonatomic, copy) NSString *longitude;
@property (nonatomic, copy) NSString *accuracy;
@property (nonatomic, copy) NSString *bearing;
@property (nonatomic, copy) NSString *locationError;
@property (nonatomic, copy) NSString *bearingError;
@property (nonatomic, copy) NSString *nextComponent;

- (id)recordLocationAndBearing;
- (NSString *)deviceCaptureScriptName;

@end
