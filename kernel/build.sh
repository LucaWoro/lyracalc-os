#!/bin/bash
# Build the LyraCalc OS kernel, modules, USB WiFi drivers and firmware (x86_64 Linux host).
#
#   ./build.sh [SDK_DIR]
#
# SDK_DIR defaults to ./rk3506-ubuntu-luckfox-lyra-w-picocalc and is cloned if missing.
# Result: out/lyracalc-kernel-<version>.tgz, installed on the PicoCalc with install-kernel.sh
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
SDK=$(readlink -f "${1:-$PWD/rk3506-ubuntu-luckfox-lyra-w-picocalc}")
BASE_REPO=https://github.com/markbirss/rk3506-ubuntu-luckfox-lyra-w-picocalc.git
BASE_COMMIT=dbacba7e158ba40b835db996b089fc99ab7c7628
OUT=$HERE/out
STAGE=$OUT/stage
SRC=$OUT/src
LOG=$OUT/build.log

mkdir -p "$OUT"
: > "$LOG"

if [ ! -d "$SDK/.git" ]; then
  echo "== Cloning the base SDK =="
  git clone "$BASE_REPO" "$SDK"
  git -C "$SDK" checkout -q "$BASE_COMMIT"
fi
K=$SDK/kernel-6.1
TC=$SDK/prebuilts/gcc/linux-x86/arm/gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf/bin/arm-none-linux-gnueabihf-

echo "== Patches =="
if grep -q fb_overlay "$K/drivers/video/fbdev/ili9488_fb.c"; then
  echo "already applied"
else
  git -C "$SDK" apply --index "$HERE"/patches/*.patch
  echo "applied $(ls "$HERE"/patches/*.patch | wc -l) patches"
fi

echo "== Kernel and boot image =="
touch "$OUT/.stamp"
( cd "$SDK" && sudo ./build.sh kernel ) >> "$LOG" 2>&1 || { echo "kernel build failed, see $LOG"; exit 1; }
KVER=$(make -s -C "$K" ARCH=arm kernelrelease)
Z=$(find "$SDK" -name zboot.img -newer "$OUT/.stamp" | head -1)
[ -n "$Z" ] || { echo "no new zboot.img, see $LOG"; exit 1; }
echo "kernel $KVER"

echo "== Modules =="
rm -rf "$STAGE"; mkdir -p "$STAGE"
make -s -C "$K" ARCH=arm CROSS_COMPILE="$TC" INSTALL_MOD_PATH="$STAGE" INSTALL_MOD_STRIP=1 modules_install >> "$LOG" 2>&1
rm -f "$STAGE/lib/modules/$KVER/build" "$STAGE/lib/modules/$KVER/source"
VENDOR=$STAGE/lib/modules/$KVER/kernel/drivers/net/wireless/realtek-vendor
mkdir -p "$VENDOR" "$STAGE/etc/modprobe.d" "$SRC"

echo "== Realtek vendor WiFi drivers =="
build_vendor() {   # github-repo module commit
  local dir
  dir=$SRC/$(basename "$1")
  if [ ! -d "$dir/.git" ]; then
    git init -q "$dir" && git -C "$dir" fetch -q --depth 1 "https://github.com/$1.git" "$3" >> "$LOG" 2>&1 \
      && git -C "$dir" checkout -q FETCH_HEAD || { echo "  download failed: $1"; rm -rf "$dir"; return; }
  fi
  ( cd "$dir" && make clean >/dev/null 2>&1; make -j"$(nproc)" ARCH=arm CROSS_COMPILE="$TC" KSRC="$K" KVER="$KVER" ) >> "$LOG" 2>&1 || true
  if [ -f "$dir/$2.ko" ]; then
    "${TC}strip" --strip-debug "$dir/$2.ko"
    cp "$dir/$2.ko" "$VENDOR/"
    echo "  $2"
  else
    echo "  $2 failed, see $LOG"
  fi
}
build_vendor morrownr/rtl8852bu-20250826 8852bu b6a299b4fe95cb6a37eec27a6c3b21cbaa6abfa8
build_vendor fofajardo/rtl8851bu 8851bu 9e37e7a1101316a05d5daede91549ea779b64539
build_vendor morrownr/8821cu-20210916 8821cu bda65aac150d2cde0df9603206eec23a6f3b77c4
build_vendor morrownr/88x2bu-20210702 88x2bu d31ffa827bb95b8a436c2a469b5163b634ac4333
build_vendor morrownr/8821au-20210708 8821au 1a819991f5b75e64dfcf922b96a6681f367cbba0
build_vendor morrownr/8812au-20210820 8812au 4722250273e4316daf9d8688e9916ea94c36a5ff
build_vendor aircrack-ng/rtl8188eus 8188eu af3bf004458f76b7aec33e9ba552cd382ed1f5c3
[ -f "$SRC/rtl8852bu-20250826/8852bu.conf" ] && cp "$SRC/rtl8852bu-20250826/8852bu.conf" "$STAGE/etc/modprobe.d/"

echo "== Firmware =="
FW=$STAGE/lib/firmware
URL=https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain
while read -r f; do
  [ -n "$f" ] && [ "${f#\#}" = "$f" ] || continue
  mkdir -p "$FW/$(dirname "$f")"
  curl -fsSL "$URL/$f" -o "$FW/$f" || { rm -f "$FW/$f"; echo "  missing $f"; }
done < "$HERE/firmware.txt"
[ -f "$FW/mediatek/mt7601u.bin" ] && cp "$FW/mediatek/mt7601u.bin" "$FW/mt7601u.bin"

echo "== Packing =="
cp "$Z" "$STAGE/zboot.img"
echo "$KVER" > "$STAGE/KVER"
tar czf "$OUT/lyracalc-kernel-$KVER.tgz" -C "$STAGE" .
ls -la "$OUT/lyracalc-kernel-$KVER.tgz"
