GO_EASY_ON_ME=1
ARCHS = armv7 arm64
TARGET = iphone:clang:latest:latest

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = Epicentre
Epicentre_FILES = Epicentre.mm
Epicentre_FILES += EpicentreRootListController.m 
Epicentre_FILES += EpicentreListController.m
Epicentre_FILES += EpicentreDiscreteSliderTableCell.m 
Epicentre_FILES += EpicentreSocialCell.m 
Epicentre_FILES += EpicentreHeaderCell.m
Epicentre_INSTALL_PATH = /Library/PreferenceBundles
Epicentre_FRAMEWORKS = UIKit
Epicentre_FRAMEWORKS += CoreGraphics
Epicentre_PRIVATE_FRAMEWORKS = Preferences
Epicentre_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Epicentre.plist$(ECHO_END)
