################################################################################
#
# rockpi-firmware
#
################################################################################

ROCKPI_FIRMWARE_VERSION = 15433d0f3f9503a0d9922dbb31668d90a56722f0
ROCKPI_FIRMWARE_SITE = $(call github,radxa,rkbin,$(ROCKPI_FIRMWARE_VERSION))
ROCKPI_FIRMWARE_INSTALL_IMAGES = YES

ROCKPI_FIRMWARE_DEPENDENCIES = uboot

define ROCKPI_FIRMWARE_BUILD_CMDS
	# $(@D)/tools/loaderimage --pack --uboot $(BINARIES_DIR)/u-boot-dtb.bin
	# $(INSTALL) -D -m 0644 $(@D)/bin/$(BR2_PACKAGE_ROCKPI_FIRMWARE_VARIANT)/bootcode.bin $(BINARIES_DIR)/rpi-firmware/bootcode.bin
	$(TARGET_CONFIGURE_OPTS) \
		$(MAKE) -C $(UBOOT_SRCDIR) $(UBOOT_MAKE_OPTS) \
		u-boot.itb
endef


define ROCKPI_FIRMWARE_INSTALL_IMAGES_CMDS
  # TODO Replicate mk-uboot.sh install from rockchip-bsp
	# $(INSTALL) -D -m 0644 $(@D)/bin/$(BR2_PACKAGE_ROCKPI_FIRMWARE_VARIANT)/bootcode.bin $(BINARIES_DIR)/rpi-firmware/bootcode.bin
endef

$(eval $(generic-package))
