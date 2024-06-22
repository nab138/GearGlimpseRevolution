TARGET = iphone:clang:latest:16.5
PACKAGE_FORMAT=ipa
INSTALL_TARGET_PROCESSES = GearGlimpseRevolution
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = GearGlimpseRevolution

GearGlimpseRevolution_FILES = src/objc/VispDetector.mm src/objc/ImageConversion.mm src/objc/ImageDisplayWithContext.mm src/objc/ImageDisplay.mm AppDelegate.swift src/FloatingUI/*.swift src/*.swift src/NetworkTables/SwiftMsgPack/*.swift src/NetworkTables/*.swift src/NetworkTables/Websockets/Compression/*.swift src/NetworkTables/Websockets/DataBytes/*.swift src/NetworkTables/Websockets/Engine/*.swift src/NetworkTables/Websockets/Framer/*.swift src/NetworkTables/Websockets/Security/*.swift src/NetworkTables/Websockets/Server/*.swift src/NetworkTables/Websockets/Starscream/*.swift src/NetworkTables/Websockets/Transport/*.swift src/utils/*.swift src/SceneKit-SCNLine/*.swift
GearGlimpseRevolution_FRAMEWORKS = UIKit CoreGraphics
GearGlimpseRevolution_EXTRA_FRAMEWORKS = opencv2 visp3
GearGlimpseRevolution_SWIFT_BRIDGING_HEADER = src/objc/VispDetector.h
GearGlimpseRevolution_CCFLAGS = -std=c++17 -Wno-deprecated-declarations -Wno-unused-but-set-variable

include $(THEOS_MAKE_PATH)/application.mk
