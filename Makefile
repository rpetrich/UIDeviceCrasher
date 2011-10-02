ifeq ($(shell [ -f ./framework/makefiles/common.mk ] && echo 1 || echo 0),0)
all clean package install::
	git submodule update --init
	./framework/git-submodule-recur.sh init
	$(MAKE) $(MAKEFLAGS) MAKELEVEL=0 $@
else

TARGET_IPHONEOS_DEPLOYMENT_VERSION = 3.0

TWEAK_NAME = __UIDeviceCrasher
__UIDeviceCrasher_OBJC_FILES = UIDeviceCrasher.m
__UIDeviceCrasher_FRAMEWORKS = Foundation UIKit

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk

endif
