#!/bin/bash
# Install a kernel pack from build.sh on the PicoCalc (boot partition, modules, firmware).
#   install-kernel.sh lyracalc-kernel-<version>.tgz
# The old boot partition is saved to /root/backup/boot/. Reboot afterwards.
set -e
[ "$(id -u)" = 0 ] || { echo "Run as root."; exit 1; }
PACK=$(readlink -f "${1:?usage: install-kernel.sh PACK.tgz}")
BOOT=/dev/mmcblk0p2
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
tar xzf "$PACK" -C "$T"
KVER=$(cat "$T/KVER")
[ "$(stat -c%s "$T/zboot.img")" -lt "$(blockdev --getsize64 $BOOT)" ] || { echo "zboot.img does not fit, nothing changed."; exit 1; }

mkdir -p /root/backup/boot
B=/root/backup/boot/boot-$(date +%Y%m%d-%H%M).img
dd if=$BOOT of="$B" status=none
echo "saved $B"

cp -a "$T/lib/modules/." /usr/lib/modules/
cp -a "$T/lib/firmware/." /usr/lib/firmware/
[ -d "$T/etc/modprobe.d" ] && cp "$T"/etc/modprobe.d/*.conf /etc/modprobe.d/ 2>/dev/null
depmod -a "$KVER"
dd if="$T/zboot.img" of=$BOOT conv=fsync status=none
sync
echo "kernel $KVER installed, reboot now"
