TARGET = iphone:clang:latest:16.5
PACKAGE_FORMAT=ipa
INSTALL_TARGET_PROCESSES = GearGlimpseRevolution

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = GearGlimpseRevolution

GearGlimpseRevolution_FILES = AppDelegate.swift RootViewController.swift src/*.swift src/NetworkTables/*.swift src/NetworkTables/Websockets/Compression/*.swift src/NetworkTables/Websockets/DataBytes/*.swift src/NetworkTables/Websockets/Engine/*.swift src/NetworkTables/Websockets/Framer/*.swift src/NetworkTables/Websockets/Security/*.swift src/NetworkTables/Websockets/Server/*.swift src/NetworkTables/Websockets/Starscream/*.swift src/NetworkTables/Websockets/Transport/*.swift
GearGlimpseRevolution_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/application.mk
