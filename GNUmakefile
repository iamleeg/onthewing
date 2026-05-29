# SPDX-License-Identifier: AGPL-3.0-or-later
#
# GNUmakefile — GNUstep build file for the OnTheWing app
# Copyright (C) 2026 Graham Lee
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

include $(GNUSTEP_MAKEFILES)/common.make
include $(GNUSTEP_MAKEFILES)/Auxiliary/gsweb_wo.make

GSWAPP_NAME=OnTheWing
OnTheWing_HAS_GSWCOMPONENTS=YES
OnTheWing_PRINCIPAL_CLASS=OTWApp
OnTheWing_GSWAPP_INFO_PLIST=Resources/Info-OTW.plist

OnTheWing_OBJC_FILES=OTW_main.m OTWApp.m Main.m Session.m DirectAction.m Capture.m AGPLFooter.m ObservationLocation.m LocationCapture.m ObservationMap.m OTWStyleSheet.m CompassSVGGenerator.m Compass.m
OnTheWing_COMPONENTS=Main.wo Capture.wo Compass.wo AGPLFooter.wo LocationCapture.wo ObservationMap.wo OTWStyleSheet.wo
OnTheWing_WEBSERVER_RESOURCE_FILES=DeviceCapture.js ObservationMap.js leaflet.js leaflet.css marker-icon.png marker-icon-2x.png marker-shadow.png layers.png layers-2x.png

ifneq ($(FOUNDATION_LIB),gnu)
AUXILIARY_GSW_LIBS = -framework WebObjects -framework WOExtensions
else
AUXILIARY_GSW_LIBS += -lWebObjects -lWOExtensions
endif

BUNDLE_NAME = OTWTests

OTWTests_OBJC_FILES = \
	test/TestApp.m \
	test/TestSession.m \
	test/TestDirectAction.m \
	test/TestMain.m \
	test/TestAGPLFooter.m \
	test/TestObservationLocation.m \
	test/TestCapture.m \
	test/TestLocationCapture.m \
	test/TestObservationMap.m \
	test/TestOTWStyleSheet.m \
	test/TestCompassSVGGenerator.m \
	OTWApp.m \
	Session.m \
	DirectAction.m \
	Main.m \
	Capture.m \
	AGPLFooter.m \
	ObservationLocation.m \
	LocationCapture.m \
	ObservationMap.m \
	OTWStyleSheet.m \
	CompassSVGGenerator.m \
	Compass.m

OTWTests_BUNDLE_LIBS = \
	-lXCTest \
	$(AUXILIARY_GSW_LIBS)

-include Makefile.preamble

include $(GNUSTEP_MAKEFILES)/gswapp.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include Makefile.postamble


internal-check:: OTWTests
	DYLD_LIBRARY_PATH=/usr/local/lib:$(DYLD_LIBRARY_PATH) \
	/usr/local/bin/xctest ./OTWTests.bundle
	npm install && npm test

podman-check:
	podman build --progress=plain --target builder -f Containerfile .
