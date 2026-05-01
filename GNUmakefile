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

OnTheWing_OBJC_FILES=OTW_main.m OTWApp.m Main.m Session.m DirectAction.m
OnTheWing_COMPONENTS=Main.wo

ifneq ($(FOUNDATION_LIB),gnu)
AUXILIARY_GSW_LIBS = -framework WebObjects -framework WOExtensions
else
AUXILIARY_GSW_LIBS += -lWebObjects -lWOExtensions
endif


-include Makefile.preamble

include $(GNUSTEP_MAKEFILES)/gswapp.make

-include Makefile.postamble

