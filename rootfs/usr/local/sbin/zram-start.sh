#!/bin/sh
# 64 MB compressed swap in RAM
modprobe zram num_devices=1
echo lzo-rle > /sys/block/zram0/comp_algorithm 2>/dev/null
echo 64M > /sys/block/zram0/disksize
mkswap /dev/zram0 >/dev/null
swapon -p 100 /dev/zram0
