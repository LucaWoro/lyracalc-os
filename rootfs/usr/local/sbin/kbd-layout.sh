#!/bin/bash
# Console keymap: USB_KEYBOARD_LAYOUT while a USB keyboard is connected, US otherwise.
# The PicoCalc keyboard itself always sends US key codes.
. /usr/local/lib/picocalc/conf.sh
L=$(pc_get USB_KEYBOARD_LAYOUT); V=$(pc_get USB_KEYBOARD_VARIANT)
[[ "$L" =~ ^[a-z]{2,3}$ ]] || L=us
[[ "$V" =~ ^[a-z0-9_-]*$ ]] || V=
usb_kbd() {
  local d
  for d in /sys/class/input/event*; do
    udevadm info -q property -p "$d" 2>/dev/null | grep -q '^ID_BUS=usb' || continue
    udevadm info -q property -p "$d" 2>/dev/null | grep -q '^ID_INPUT_KEYBOARD=1' && return 0
  done
  return 1
}
if [ "$L" != us ] && usb_kbd; then MAP=$L${V:+-$V}; else MAP=us; fi
S=/run/lyracalc/kbd-layout
[ "$MAP" = "$(cat "$S" 2>/dev/null || echo us)" ] && exit 0
C=/var/cache/lyracalc/keymaps
mkdir -p "$C"
if [ ! -s "$C/$MAP.map" ]; then
  if [ "$MAP" = us ]; then ckbcomp -layout us > "$C/$MAP.map" 2>/dev/null
  else ckbcomp -layout "$L" ${V:+-variant "$V"} > "$C/$MAP.map" 2>/dev/null; fi
fi
[ -s "$C/$MAP.map" ] || { rm -f "$C/$MAP.map"; logger "kbd-layout: unknown layout $MAP"; exit 0; }
loadkeys -q -C /dev/tty1 "$C/$MAP.map" || exit 0
mkdir -p /run/lyracalc; echo "$MAP" > "$S"
logger "kbd-layout: $MAP"
