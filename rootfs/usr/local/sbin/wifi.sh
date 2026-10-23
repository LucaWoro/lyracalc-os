#!/bin/bash
# Usage: wifi.sh up|down <interface>
IF="$2"
PID="/run/wpa_supplicant-$IF.pid"
case "$1" in
  up)
    ip link set "$IF" up
    [ -f "$PID" ] && kill "$(cat "$PID")" 2>/dev/null && sleep 1
    wpa_supplicant -B -i "$IF" -D nl80211,wext -c /etc/wpa_supplicant.conf -P "$PID"
    dhclient -nw "$IF"
    ;;
  down)
    dhclient -r "$IF" 2>/dev/null
    [ -f "$PID" ] && kill "$(cat "$PID")" 2>/dev/null
    ;;
esac
