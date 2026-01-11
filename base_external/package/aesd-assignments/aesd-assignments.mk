
##############################################################
#
# AESD-ASSIGNMENTS
#
##############################################################

#Referencing my assignment 3 git contents
AESD_ASSIGNMENTS_VERSION = 2061ea52558974386563b6abd3b634ba8e607e09
# Note: Be sure to reference the *ssh* repository URL here (not https) to work properly with ssh keys and the automated build/test system.
# Our site should start with git@github.com:
AESD_ASSIGNMENTS_SITE = git@github.com:cu-ecen-aeld/assignments-3-and-later-biplavpoudel.git
AESD_ASSIGNMENTS_SITE_METHOD = git
AESD_ASSIGNMENTS_GIT_SUBMODULES = YES

define AESD_ASSIGNMENTS_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) CC="$(TARGET_CC)" -C $(@D)/finder-app all
	$(MAKE) $(TARGET_CONFIGURE_OPTS) CC="$(TARGET_CC)" -C $(@D)/server all
endef

# Adding our writer, finder and finder-test utilities/scripts as well as aesdsocket and its init script to the installation steps below
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

	@echo "Installing Init script for aesdsocket"
	$(INSTALL) -d $(TARGET_DIR)/etc/init.d
	$(INSTALL) -m 0755 $(@D)/server/aesdsocket-start-stop.sh $(TARGET_DIR)/etc/init.d/S99aesdsocket

	@echo "Installing aesdsocket binary for server from $(AESD_ASSIGNMENTS_SITE)..."
	$(INSTALL) -m 0755 $(@D)/server/aesdsocket $(TARGET_DIR)/usr/bin

endef

$(eval $(generic-package))
