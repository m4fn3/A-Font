include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = AFontPrefs
AFontPrefs_FILES = AFPRootListController.m AFPBlackListController.m
AFontPrefs_INSTALL_PATH = /Library/PreferenceBundles
AFontPrefs_FRAMEWORKS = UIKit
AFontPrefs_PRIVATE_FRAMEWORKS = Preferences CoreServices
# AFontPrefs_LIBRARIES = applist

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/AFontPrefs.plist$(ECHO_END)
