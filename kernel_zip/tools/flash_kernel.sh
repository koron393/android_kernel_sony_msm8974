#!/sbin/sh
#
# Live ramdisk patching script
#
# This software is licensed under the terms of the GNU General Public
# License version 2, as published by the Free Software Foundation, and
# may be copied, distributed, and modified under those terms.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# Please maintain this if you use this script or any part of it

# Head to the build tools extracted folder
cd /tmp;

# Get current boot.img first then unpack it
dd if=/dev/block/platform/msm_sdcc.1/by-name/boot of=/tmp/boot.img;
./unpackbootimg -i /tmp/boot.img;

# Initialize boot.img's properties
base=$(cat *-base);
cmdline=$(cat *-cmdline);
pagesize=$(cat *-pagesize);
ramdisk_offset=$(cat *-ramdisk_offset);
tags_offset=$(cat *-tags_offset);

## Extract ramdisk
mkdir -p /tmp/ramdisk;
cd /tmp/ramdisk;
# Here we only support gzip ramdisk, as it's begin widely used
gunzip -c ../boot.img-ramdisk.gz | $bb cpio -i;

# Pack ramdisk with RZ's extra rc file
cp -f /tmp/ramdisk-RZ/* /tmp/ramdisk;
sed -i 's:init.qcom.power.rc:init.RZ.rc:g' /tmp/ramdisk/init.qcom.rc;
cd /tmp;
./mkbootfs /tmp/ramdisk/ > /tmp/boot.img-ramdisk;
cat /tmp/boot.img-ramdisk | gzip > /tmp/boot.img-ramdisk.gz

# Pack our new boot.img
./mkbootimg --kernel /tmp/zImage --ramdisk /tmp/boot.img-ramdisk.gz --cmdline "$cmdline androidboot.selinux=permissive" --base $base --pagesize $pagesize --ramdisk_offset /tmp/ramdisk_offset --tags_offset $tags_offset --dt /tmp/dt.img -o /tmp/newboot.img;

# It's flashing time!!
dd if=/tmp/newboot.img of=/dev/block/platform/msm_sdcc.1/by-name/boot;
