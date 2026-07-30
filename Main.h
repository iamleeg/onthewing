// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Main.h - Landing Page
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

/**
<title>Main - The landing page for OnTheWing</title>
 */

#include <WebObjects/WebObjects.h>

/**
 A component that renders the main user interface for the OnTheWing app.

 */
@interface Main : GSWComponent {
}

/**
 An action an observer calls to capture an observation.
 Observations are "pending" in the Session until an observer reviews them in the ReviewObservations interface,
 and either deletes them or adds them to their journal.
 */
- capture;
/**
 An action an observer calls to review their pending observations.
 */
- (id)reviewObservations;
/**
 An action an observer calls to browse their nature journal.
 */
- (id)browseJournal;
/**
 A Boolean value that indicates whether the observer has pending observations in their Session.
 Returns YES if there are any pending observations; NO otherwise.
 */
- (BOOL)hasObservations;
/**
 A string that indicates to an observer whether they have pending observations in their Session.
 */
- (NSString *)reportPendingObservations;
/**
 A Boolean value that indicates whether the Session is associated with an observer.
 Returns YES if an Observer is authenticated in the Session; NO otherwise.
 */
- (BOOL)hasUser;

/**
 A Boolean value that indicates whether the OTWApp is ready to receive external requests.
 This component displays a placeholder UI when this method returns NO.
 */
- (BOOL)isAppReady;

@end
