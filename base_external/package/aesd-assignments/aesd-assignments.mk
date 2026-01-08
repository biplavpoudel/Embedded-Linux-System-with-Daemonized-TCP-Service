
##############################################################
#
# AESD-ASSIGNMENTS
#
##############################################################

#Referencing my assignment 3 git contents
AESD_ASSIGNMENTS_VERSION = 4b7d44f367728a9b39cafa637c05fc081b4d5dff
# Note: Be sure to reference the *ssh* repository URL here (not https) to work properly with ssh keys and the automated build/test system.
# Our site should start with git@github.com:
AESD_ASSIGNMENTS_SITE = git@github.com:cu-ecen-aeld/assignments-3-and-later-biplavpoudel.git
AESD_ASSIGNMENTS_SITE_METHOD = git
AESD_ASSIGNMENTS_GIT_SUBMODULES = YES

define AESD_ASSIGNMENTS_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) CC="$(TARGET_CC)" -C $(@D)/finder-app all
endef

# Adding our writer, finder and finder-test utilities/scripts to the installation steps below
define AESD_ASSIGNMENTS_INSTALL_TARGET_CMDS
	@echo "Installing configuration files from ${AESD_ASSIGNMENTS_SITE}..."
	$(INSTALL) -d 0755 $(TARGET_DIR)/etc/finder-app/conf/
	$(INSTALL) -m 0644 $(@D)/conf/* $(TARGET_DIR)/etc/finder-app/conf/
	
	@echo "Installing autotest scripts from $(AESD_ASSIGNMENTS_SITE)..."
	$(INSTALL) -m 0755 $(@D)/assignment-autotest/test/assignment4/* $(TARGET_DIR)/usr/bin
	
	@echo "Installing binaries for finder-app from $(AESD_ASSIGNMENTS_SITE)..."
	$(INSTALL) -d 0755 $(TARGET_DIR)/usr/bin
	$(INSTALL) -m 0755 $(@D)/finder-app/writer $(TARGET_DIR)/usr/bin
	$(INSTALL) -m 0755 $(@D)/finder-app/finder.sh $(TARGET_DIR)/usr/bin
	$(INSTALL) -m 0755 $(@D)/finder-app/finder-test.sh $(TARGET_DIR)/usr/bin
endef

$(eval $(generic-package))
