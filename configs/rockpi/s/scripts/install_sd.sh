#!/bin/bash

RSYNC="rsync -rav --no-perms --no-owner --no-group"

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

set -e
if [ -z "$PI_SD" ]; then
  echo "Please set PI_SD and try again."
  exit 1
fi

if [ ! -b "$PI_SD" ]; then
  echo "$PI_SD is not a block device or doesn't exist."
  exit 1
fi

PI_SD_SFX=$PI_SD
if [ -b ${PI_SD}p1 ]; then
  PI_SD_SFX=${PI_SD}p
fi

outp_path="${BUILDROOT_DIR}/output"
images_path="${outp_path}/images"
uimg_path="${outp_path}/images/Image"
cpio_path="${outp_path}/images/rootfs.cpio.gz"

if [ ! -f "$uimg_path" ]; then
  echo "Image not found, make sure Buildroot is done compiling."
  exit 1
fi

mounts=()
WORK_DIR=`mktemp -d -p "$DIR"`
# deletes the temp directory
function cleanup {
sync || true
for mount in "${mounts[@]}"; do
  echo "Unmounting ${mount}..."
  umount $mount || true
done
mounts=()
if [ -d "$WORK_DIR" ]; then
  rm -rf "$WORK_DIR" || true
fi
}
trap cleanup EXIT

boot_dir="${WORK_DIR}/boot"
rootfs_dir="${WORK_DIR}/rootfs"
persist_dir="${WORK_DIR}/persist"

mkdir -p $boot_dir
echo "Mounting ${PI_SD_SFX}1 to $boot_dir..."
mounts+=("$boot_dir")
mount ${PI_SD_SFX}4 $boot_dir

echo "Mounting ${PI_SD_SFX}2 to $rootfs_dir..."
mkdir -p $rootfs_dir
mounts+=("$rootfs_dir")
mount ${PI_SD_SFX}5 $rootfs_dir

echo "Mounting ${PI_SD_SFX}3 to $persist_dir..."
mkdir -p $persist_dir
mounts+=("$persist_dir")
mount ${PI_SD_SFX}6 $persist_dir

echo "Copying kernel..."
$RSYNC $uimg_path $boot_dir/Image
sync

if [ -d "$outp_path/images/rootfs_part" ]; then
  echo "Copying rootfs_part..."
  $RSYNC $outp_path/images/rootfs_part/ $rootfs_dir/
  sync
fi

if [ -d "$outp_path/images/persist_part" ]; then
  echo "Copying persist_part..."
  $RSYNC $outp_path/images/persist_part/ $persist_dir/
  sync
fi

echo "Copying device tree(s)..."
$RSYNC $outp_path/images/*.dtb $boot_dir/
sync

echo "Copying uInitrd..."
$RSYNC $cpio_path $boot_dir/rootfs.cpio.gz
sync

enable_silent() {
    if [ -f "$images_path/.disable-serial-console" ]; then
        echo "Disabling serial console and enabling silent mode..."
        sed -i -e "/^setenv condev/s/^/# /" -e "s/# setenv silent/setenv silent/" $1
    fi
}

echo "Compiling boot.txt..."
cp ${SKIFF_CURRENT_CONF_DIR}/resources/boot-scripts/boot.txt $boot_dir/boot.txt
enable_silent $boot_dir/boot.txt
mkimage -A arm -C none -T script -n 'Skiff Rockpi S' -d $boot_dir/boot.txt $boot_dir/boot.scr

cleanup
