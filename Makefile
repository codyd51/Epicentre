GO_EASY_ON_ME=1
ARCHS = armv7 arm64
TARGET = iphone:clang:latest:latest
THEOS_BUILD_DIR = Packages

include theos/makefiles/common.mk

TWEAK_NAME = Epicentre
Epicentre_FILES = Tweak.xm
Epicentre_FILES += EPCPreferences.mm
Epicentre_FILES += EPCDraggableRotaryNumberView.mm
Epicentre_FILES += EPCExpandingChestView.mm
Epicentre_FILES += EPCRingView.mm
Epicentre_FILES += EPCPasscodeChangedAlertWrapper.mm
Epicentre_FILES += EPCPasscodeChangedAlertHandler.mm
#Epicentre_FILES += EPCRingController.mm
Epicentre_FRAMEWORKS = UIKit
Epicentre_FRAMEWORKS += CoreGraphics
Epicentre_FRAMEWORKS += QuartzCore
Epicentre_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
