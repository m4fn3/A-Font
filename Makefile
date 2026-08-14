TARGET = iphone:clang:16.5:15.6
PREFIX="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/"
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AFont
AFont_FILES = Tweak.xm

ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
AFont_LDFLAGS += -lroothide
endif
# AFont_PRIVATE_FRAMEWORKS = AppSupport

# export STRCRY = 1
# export INDIBRAN = 1
# AFont_CFLAGS = -Xclang -load -Xclang /Library/Developer/HikariCore/libLLVMObfuscationHook.dylib

include $(THEOS_MAKE_PATH)/tweak.mk

# after-install::
# 	install.exec "killall -9 SpringBoard"
SUBPROJECTS += afontprefs
include $(THEOS_MAKE_PATH)/aggregate.mk

# The font directory has to be writable by the downloader. Baking the mode into
# the package beats a postinst, which has to guess the install prefix and got it
# wrong under at least one scheme.
internal-stage::
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -type d -name A-Font -exec chmod 777 {} +$(ECHO_END)
