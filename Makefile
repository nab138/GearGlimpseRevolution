TARGET = iphone:clang:latest:16.5
PACKAGE_FORMAT=ipa
INSTALL_TARGET_PROCESSES = GearGlimpseRevolution

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = GearGlimpseRevolution

GearGlimpseRevolution_FILES = AppDelegate.swift RootViewController.swift src/*.swift
GearGlimpseRevolution_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/application.mk
