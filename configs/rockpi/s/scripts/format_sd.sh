#!/bin/bash

LOADER1_SIZE=8000
RESERVED1_SIZE=128
RESERVED2_SIZE=8192
LOADER2_SIZE=8192
ATF_SIZE=8192
BOOT_SIZE=229376

SYSTEM_START=0
LOADER1_START=64
RESERVED1_START=$(expr ${LOADER1_START} + ${LOADER1_SIZE})
RESERVED2_START=$(expr ${RESERVED1_START} + ${RESERVED1_SIZE})
LOADER2_START=$(expr ${RESERVED2_START} + ${RESERVED2_SIZE})
ATF_START=$(expr ${LOADER2_START} + ${LOADER2_SIZE})
BOOT_START=$(expr ${ATF_START} + ${ATF_SIZE})
ROOTFS_START=$(expr ${BOOT_START} + ${BOOT_SIZE})

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

set -e
if ! parted -h > /dev/null; then
  echo "Please install 'parted' and try again."
  exit 1
fi

if ! command -v mkfs.vfat >/dev/null 2>&1; then
  echo "Please install 'mkfs.vfat' and try again."
  exit 1
fi

outp_path="${BUILDROOT_DIR}/output"
idbloader_path="${outp_path}/images/rockpi-idbloader.img"
uboot_path="${outp_path}/images/rockpi-uboot.img"
trust_path="${outp_path}/images/rockpi-trust.img"

if [ ! -f $idbloader_path ]; then
    echo "idbloader not found at $idbloader_path"
    exit 1
fi
if [ ! -f $uboot_path ]; then
    echo "uboot not found at $uboot_path"
    exit 1
fi
if [ ! -f $trust_path ]; then
    echo "trustzone not found at $trust_path"
    exit 1
fi

if [ -z "$PI_SD" ]; then
  echo "Please set PI_SD and try again."
  exit 1
fi

if [ -z "$SKIFF_NO_INTERACTIVE" ]; then
  read -p "Are you sure? This will completely destroy all data. [y/N] " -n 1 -r
  echo
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

if [ -z "$SKIFF_NO_INTERACTIVE" ]; then
  read -p "Verify that '$PI_SD' is the correct device. Be sure. [y/N] " -n 1 -r
  echo
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

set -x
set -e

echo "Formatting device..."
parted $PI_SD mklabel gpt
sleep 1

echo "Making boot partition..."
# The S requires some headroom for bootloader
parted -s $PI_SD unit s mkpart loader1 ${LOADER1_START} $(expr ${RESERVED1_START} - 1)
# parted -s ${SYSTEM} unit s mkpart reserved1 ${RESERVED1_START} $(expr ${RESERVED2_START} - 1)
# parted -s ${SYSTEM} unit s mkpart reserved2 ${RESERVED2_START} $(expr ${LOADER2_START} - 1)
parted -s $PI_SD unit s mkpart loader2 ${LOADER2_START} $(expr ${ATF_START} - 1)
parted -s $PI_SD unit s mkpart trust ${ATF_START} $(expr ${BOOT_START} - 1)
parted -s $PI_SD unit s mkpart boot ${BOOT_START} 500M
sleep 1

PI_SD_SFX=$PI_SD
if [ -b ${PI_SD}p1 ]; then
  PI_SD_SFX=${PI_SD}p
fi

mkfs.vfat -n BOOT -F 16 ${PI_SD_SFX}4
parted $PI_SD set 4 boot on
sleep 1
# mlabel -i ${PI_SD_SFX}1 ::boot

echo "Making rootfs partition..."
parted -s -a optimal $PI_SD mkpart primary ext4 500M 900MiB
sleep 1
mkfs.ext4 -F -L "rootfs" -O ^64bit ${PI_SD_SFX}5

echo "Making persist partition..."
parted -s -a optimal $PI_SD mkpart primary ext4 900MiB 100%
sleep 1
mkfs.ext4 -F -L "persist" -O ^64bit ${PI_SD_SFX}6

sync && sync
sleep 1


echo "Flashing u-boot and trustzone..."
dd conv=notrunc if=${idbloader_path} of=${PI_SD} seek=64
dd conv=notrunc if=${uboot_path} of=${PI_SD} seek=16384
dd conv=notrunc if=${trust_path} of=${PI_SD} seek=24576
# dd if=boot.img of=${PI_SD} seek=32768
# dd if=rootfs.img of= seek=262144
cd -
