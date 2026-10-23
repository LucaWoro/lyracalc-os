#!/bin/bash
# Make a release image from a LyraCalc OS SD card (Linux host, card in a USB reader).
# The card is only read. Left out: WiFi networks, PICO-8, /root (except .bashrc/.profile),
# shell history, logs, Bluetooth pairings, SSH host keys, machine-id, apt caches.
# Set: login root/root, default settings, setup wizard and first-boot service on.
# The root filesystem is rebuilt at the size of its content and compressed with xz.
#   sudo ./make-release-image.sh
set -e
[ "$(id -u)" = 0 ] || { echo "Please run with sudo: sudo bash $0"; exit 1; }
for t in sfdisk mkfs.ext4 dumpe2fs rsync xz openssl blkid lsblk losetup sha256sum; do
  command -v "$t" >/dev/null || { echo "Missing tool: $t  (sudo apt install fdisk e2fsprogs rsync xz-utils openssl)"; exit 1; }
done
HOMEDIR=$(getent passwd "${SUDO_USER:-root}" | cut -d: -f6)
OUT=$HOMEDIR/lyracalc-release
SRC=$OUT/mnt-card
DST=$OUT/mnt-image
LOOP=""
cleanup() {
  mountpoint -q "$DST" && umount "$DST"
  mountpoint -q "$SRC" && umount "$SRC"
  [ -n "$LOOP" ] && losetup -d "$LOOP" 2>/dev/null
  true
}
trap cleanup EXIT
mkdir -p "$OUT" "$SRC" "$DST"

echo "== 1/7: Choose the SD card =="
SYSDISK=$(lsblk -no PKNAME "$(findmnt -no SOURCE /)" 2>/dev/null | head -1)
CANDS=()
for d in $(lsblk -dpno NAME); do
  b=${d##*/}
  case "$b" in loop*|sr*|zram*|ram*) continue ;; esac
  [ "$b" = "$SYSDISK" ] && continue
  tran=$(lsblk -dno TRAN "$d" | tr -d ' '); rm=$(lsblk -dno RM "$d" | tr -d ' ')
  case "$tran$rm$b" in usb*|mmc*|*1"$b"|*mmcblk*) CANDS+=("$d") ;; esac
done
[ ${#CANDS[@]} -gt 0 ] || { echo "No SD card found. Insert the PicoCalc card and try again."; exit 1; }
i=1
for d in "${CANDS[@]}"; do
  printf ' %d) %s  %s  %s\n' $i "$d" "$(lsblk -dno SIZE "$d" | tr -d ' ')" "$(lsblk -dno MODEL "$d")"
  i=$((i + 1))
done
read -rp "Number of the PicoCalc SD card: " n
DEV=${CANDS[$((n - 1))]}
[ -n "$DEV" ] || { echo "Invalid choice."; exit 1; }
lsblk -po NAME,SIZE,FSTYPE,LABEL "$DEV"
read -rp "Use $DEV? It is only read, never changed. Type yes: " a
[ "$a" = yes ] || { echo "Cancelled."; exit 1; }
for p in $(lsblk -lnpo NAME "$DEV" | tail -n +2); do umount "$p" 2>/dev/null || true; done

echo "== 2/7: Root filesystem =="
ROOTP=""
for p in $(lsblk -lnpo NAME,TYPE "$DEV" | awk '$2 == "part" {print $1}'); do
  [ "$(blkid -s TYPE -o value "$p")" = ext4 ] || continue
  mount -o ro,noload "$p" "$SRC" 2>/dev/null || continue
  if [ -f "$SRC/etc/os-release" ] && [ -d "$SRC/usr/lib/modules" ]; then ROOTP=$p; break; fi
  umount "$SRC"
done
[ -n "$ROOTP" ] || { echo "No Linux root filesystem found on $DEV."; exit 1; }
VER=$(sed -n 's/^LC_VERSION="\(.*\)"/\1/p' "$SRC/etc/lyracalc-release" 2>/dev/null)
NAME=lyracalc-os-${VER:-$(date +%Y%m%d)}
IMG=$OUT/$NAME.img
RB=${ROOTP##*/}
PN=$(cat "/sys/class/block/$RB/partition")
START=$(cat "/sys/class/block/$RB/start")
for q in /sys/class/block/"${DEV##*/}"/"${DEV##*/}"*; do
  [ "$(cat "$q/start")" -gt "$START" ] && { echo "The root partition is not the last one. Not supported."; exit 1; }
done
UUID=$(blkid -s UUID -o value "$ROOTP")
LABEL=$(blkid -s LABEL -o value "$ROOTP" || true)
echo "Root: $ROOTP (partition $PN, starts at sector $START, UUID $UUID)"

echo "== 3/7: Size =="
FILTER=$OUT/filter.txt
cat > "$FILTER" << 'EOF'
+ /root/
+ /root/.bashrc
+ /root/.profile
- /root/*
- /home/*/.ssh/
- /etc/ssh/ssh_host_*
- /etc/wpa_supplicant.conf.*
- /etc/NetworkManager/system-connections/*
- /var/lib/bluetooth/*
- /var/lib/dhcp/*
- /var/lib/lyracalc/wifi-ip
- /var/cache/lyracalc/
- /etc/keymaps/
- /etc/X11/xorg.conf.d/91-usb-keyboard.conf
- /var/lib/systemd/random-seed
- /var/cache/apt/*.bin
- /var/cache/apt/archives/*.deb
+ /var/lib/apt/lists/partial/
- /var/lib/apt/lists/partial/*
- /var/lib/apt/lists/*
+ /var/log/**/
- /var/log/**
- /tmp/*
- /var/tmp/*
- /swapfile
- /lost+found
- .bash_history
- .python_history
- .lesshst
- .viminfo
- .wget-hsts
EOF
STATS=$(rsync -aHAX --dry-run --stats --filter="merge $FILTER" "$SRC/" "$OUT/does-not-exist/")
BYTES=$(echo "$STATS" | sed -n 's/^Total file size: \([0-9,]*\).*/\1/p' | tr -d ',')
FILES=$(echo "$STATS" | sed -n 's/^Number of files: \([0-9,]*\).*/\1/p' | tr -d ',')
FSMB=$(( BYTES / 1048576 * 115 / 100 + 300 ))
INODES=$(( FILES * 2 + 20000 ))
echo "Content: $((BYTES / 1048576)) MB in $FILES files -> filesystem $FSMB MB"
FREE=$(df -Pm "$OUT" | awk 'NR == 2 {print $4}')
[ "$FREE" -gt $(( FSMB * 2 + START / 2048 + 500 )) ] || { echo "Not enough free space in $OUT ($FREE MB)."; exit 1; }

echo "== 4/7: Empty image =="
rm -f "$IMG" "$IMG.xz"
dd if="$DEV" of="$IMG" bs=512 count="$START" status=none
truncate -s $(( START * 512 + FSMB * 1048576 + 1048576 )) "$IMG"
sfdisk -d "$DEV" | sed '/^last-lba:/d; /^device:/d' | sed -E "s|^/dev/[^ ]+ : ||" \
  | awk -v n="$PN" -v sz=$(( FSMB * 2048 )) '
      /^start=/ { c++; if (c == n) sub(/size= *[0-9]+/, "size=" sz) } { print }' > "$OUT/table.txt"
sfdisk --no-reread --no-tell-kernel "$IMG" < "$OUT/table.txt" > /dev/null
LOOP=$(losetup -fP --show "$IMG")
sleep 1
FEAT=$(dumpe2fs -h "$ROOTP" 2>/dev/null | sed -n 's/^Filesystem features:[[:space:]]*//p')
OPT=""
for f in orphan_file metadata_csum_seed; do
  echo " $FEAT " | grep -q " $f " || { grep -q "$f" /etc/mke2fs.conf 2>/dev/null && OPT="$OPT,^$f"; }
done
mkfs.ext4 -q -F -U "$UUID" ${LABEL:+-L "$LABEL"} -N "$INODES" ${OPT:+-O "${OPT#,}"} "${LOOP}p$PN"
mount "${LOOP}p$PN" "$DST"

echo "== 5/7: Copying =="
rsync -aHAX --numeric-ids --filter="merge $FILTER" "$SRC/" "$DST/"

echo "== 6/7: Defaults and first boot =="
# WiFi: drop saved networks and the country
if [ -f "$DST/etc/wpa_supplicant.conf" ]; then
  awk '/^[[:space:]]*network[[:space:]]*=[[:space:]]*\{/ {n = 1}
       n == 0 && !/^country=/ {print}
       n == 1 && /^[[:space:]]*\}/ {n = 0}' "$SRC/etc/wpa_supplicant.conf" > "$DST/etc/wpa_supplicant.conf"
fi
# default settings
cp "$DST/usr/local/share/lyracalc/picocalc.conf.default" "$DST/etc/picocalc.conf"
echo "options picocalc_snd_pwm mute=0 idle_ms=2000" > "$DST/etc/modprobe.d/picocalc-audio-state.conf"
printf 'lyra\n' > "$DST/etc/hostname"
printf '127.0.0.1\tlocalhost\n127.0.1.1\tlyra\n\n::1\tip6-localhost ip6-loopback\nff02::1\tip6-allnodes\nff02::2\tip6-allrouters\n' > "$DST/etc/hosts"
sed -i '/^\/swapfile[[:space:]]/d' "$DST/etc/fstab"
[ -f "$DST/etc/gpm.conf" ] && printf 'device=/dev/input/mice\nresponsiveness=\nrepeat_type=ms3\ntype=exps2\nappend=\x27\x27\nsample_rate=\n' > "$DST/etc/gpm.conf"
# login root / root
H=$(openssl passwd -6 root)
awk -F: -v OFS=: -v h="$H" '$1 == "root" {$2 = h} {print}' "$DST/etc/shadow" > "$OUT/shadow.new"
cat "$OUT/shadow.new" > "$DST/etc/shadow"; rm -f "$OUT/shadow.new"
# recreated at first boot
: > "$DST/etc/machine-id"
[ -f "$DST/var/lib/dbus/machine-id" ] && [ ! -L "$DST/var/lib/dbus/machine-id" ] && rm -f "$DST/var/lib/dbus/machine-id"
touch "$DST/etc/picocalc-firstboot"
chmod 700 "$DST/root"

echo "== 7/7: Checks and compressing =="
WARN=0
L=$(grep -rIlE '^[[:space:]]*(psk|password|sae_password)=' "$DST/etc" "$DST/root" 2>/dev/null || true)
[ -n "$L" ] && { echo "WARNING: possible WiFi passwords in:"; echo "$L"; WARN=1; }
L=$(find "$DST" -xdev \( -name 'pico8_dyn' -o -name 'pico8' -size +500k -o -name '*.p8' -o -name '*.p8.png' -o -name 'pico-8*raspi*.zip' \) 2>/dev/null || true)
[ -n "$L" ] && { echo "WARNING: PICO-8 files found:"; echo "$L"; WARN=1; }
[ -e "$DST/etc/picocalc-firstboot" ] || { echo "WARNING: first-boot flag missing"; WARN=1; }
[ -x "$DST/usr/local/sbin/picocalc-firstboot" ] || { echo "WARNING: picocalc-firstboot missing, run install.sh on the PicoCalc first"; WARN=1; }
df -h "$DST" | tail -1
umount "$DST"; umount "$SRC"
losetup -d "$LOOP"; LOOP=""
xz -T0 -6 "$IMG"
( cd "$OUT" && sha256sum "$NAME.img.xz" > "$NAME.img.xz.sha256" )
chown -R "${SUDO_USER:-root}": "$OUT" 2>/dev/null || true
echo ""
ls -la "$IMG.xz"
[ "$WARN" = 0 ] && echo "All checks passed." || echo "Check the warnings above before publishing!"
echo "Done: $IMG.xz"
