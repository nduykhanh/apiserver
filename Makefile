THEOS_PLATFORM_DEB_COMPRESSION_TYPE = gzip
ARCHS = arm64
DEBUG = 0
# THEOS = /home/ubuntu/theos
THEOS_MAKE_PATH = /home/ubuntu/theos/makefiles
# TARGET = iphone:13.6
# FINALPACKAGE = 1
# FOR_RELEASE = 1
IGNORE_WARNINGS = 1
 
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = Key
$(TWEAK_NAME)_FRAMEWORKS = UIKit Accelerate Foundation QuartzCore CoreGraphics AudioToolbox CoreText Metal MobileCoreServices Security SystemConfiguration IOKit CoreTelephony CoreImage CFNetwork AdSupport AVFoundation
$(TWEAK_NAME)_FILES = hash.mm API/VoVong.mm $(wildcard Support/*.m)
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-value
$(TWEAK_NAME)_CCFLAGS = -fno-rtti -fvisibility=hidden -DNDEBUG -std=c++11
include $(THEOS_MAKE_PATH)/tweak.mk

