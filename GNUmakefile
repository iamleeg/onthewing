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

