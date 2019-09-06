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
	mkdir -p $(@D)/rockpi-bin
	# produce uboot.img
	$(@D)/tools/loaderimage \
		--pack --uboot $(BINARIES_DIR)/u-boot-dtb.bin \
		$(@D)/rockpi-bin/uboot.img 0x600000 --size 1024 1
	# produce idbloader
	$(UBOOT_SRCDIR)/tools/mkimage -n rk3308 -T rksd \
		-d $(@D)/bin/rk33/rk3308_ddr_589MHz_uart0_m0_v1.26.bin \
		$(@D)/rockpi-bin/idbloader.img
	cat $(@D)/bin/rk33/rk3308_miniloader_v1.13.bin >> $(@D)/rockpi-bin/idbloader.img
	# produce trust zone
	cd $(@D); $(@D)/tools/trust_merger --size 1024 1 $(@D)/RKTRUST/RK3308TRUST.ini
	mv $(@D)/trust.img $(@D)/rockpi-bin/trust.img
	# $(INSTALL) -D -m 0644 $(@D)/bin/$(BR2_PACKAGE_ROCKPI_FIRMWARE_VARIANT)/bootcode.bin $(BINARIES_DIR)/rpi-firmware/bootcode.bin
	#$(TARGET_CONFIGURE_OPTS) \
	#	$(MAKE) -C $(UBOOT_SRCDIR) $(UBOOT_MAKE_OPTS) \
	#	u-boot.itb
endef


define ROCKPI_FIRMWARE_INSTALL_IMAGES_CMDS
	# idbloader.img is flashed to 0x40
	$(INSTALL) -D -m 0644 $(@D)/rockpi-bin/idbloader.img $(BINARIES_DIR)/rockpi-idbloader.img
	# uboot.img is flashed to 0x4000
	$(INSTALL) -D -m 0644 $(@D)/rockpi-bin/uboot.img $(BINARIES_DIR)/rockpi-uboot.img
	# trust.img is flashed to 0x6000
	$(INSTALL) -D -m 0644 $(@D)/rockpi-bin/trust.img $(BINARIES_DIR)/rockpi-trust.img
	# boot partition should start at offset 0x8000
endef

$(eval $(generic-package))
