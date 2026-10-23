#!/bin/bash
# Shared WiFi functions
CONF=/etc/wpa_supplicant.conf
PCONF=/etc/picocalc.conf

wifi_if() { for d in /sys/class/net/wl*; do [ -e "$d" ] && { basename "$d"; return; }; done; }
IF=$(wifi_if)

wcli() { wpa_cli -i "$IF" "$@" 2>/dev/null; }

wifi_mode() { [ -e "/sys/class/net/$IF/phy80211" ] && echo nl80211 || echo wext; }

need_wifi() {
  if [ -z "$IF" ]; then
    echo "No WiFi stick found. Plug it in (and check: lsusb)."; exit 1
  fi
  if [ "$(wcli ping)" != "PONG" ]; then
    echo "WiFi is off. Turn it on with: wifion"; exit 1
  fi
}

# signal (dBm or quality) -> percent
sig_pct() {
  local s=$1
  if [ "$s" -lt 0 ]; then s=$(( (s + 100) * 2 )); fi
  [ "$s" -gt 100 ] && s=100; [ "$s" -lt 0 ] && s=0
  echo "$s"
}

sec_name() {
  case "$1" in
    *SAE*) echo "WPA3" ;;
    *WPA2*|*RSN*) echo "WPA2" ;;
    *WPA*) echo "WPA" ;;
    *WEP*) echo "WEP" ;;
    *) echo "open" ;;
  esac
}

# scan; prints "percent<TAB>security<TAB>ssid", strongest first, one line per name
wifi_scan() {
  wcli scan >/dev/null
  local i
  for i in 1 2 3 4 5 6; do
    sleep 1
    [ "$(wcli scan_results | tail -n +2 | wc -l)" -gt 0 ] && [ "$i" -ge 3 ] && break
  done
  wcli scan_results | tail -n +2 | awk -F'\t' '$5 != "" {print $3 "\t" $4 "\t" $5}' \
    | sort -t$'\t' -k1,1nr | awk -F'\t' '!seen[$3]++' \
    | while IFS=$'\t' read -r sig flags ssid; do
        printf '%s\t%s\t%s\n' "$(sig_pct "$sig")" "$(sec_name "$flags")" "$ssid"
      done
}

saved_id() {   # id of a saved network with this name, if any
  wcli list_networks | tail -n +2 | awk -F'\t' -v s="$1" '$2 == s {print $1; exit}'
}
current_ssid() { wcli status | sed -n 's/^ssid=//p'; }

# print a numbered network table from lines "percent<TAB>security<TAB>ssid"
print_table() {
  local cur n=0 p sec ssid mark
  cur=$(current_ssid)
  printf ' #  Sig  Sec   Name\n'
  while IFS=$'\t' read -r p sec ssid; do
    n=$((n + 1)); mark=""
    [ -n "$(saved_id "$ssid")" ] && mark=" *"
    [ "$ssid" = "$cur" ] && ssid=">$ssid"
    printf '%2d %3d%%  %-4s  %s%s\n' "$n" "$p" "$sec" "$ssid" "$mark"
  done
  echo "(> connected, * saved)"
}

hexstr() { printf '%s' "$1" | od -An -tx1 | tr -d ' \n'; }

get_ip() { ip -4 addr show dev "$IF" 2>/dev/null | awk '/inet / {sub(/\/.*/, "", $2); print $2; exit}'; }

# try to connect to network id $1 (new=1: remove it again on failure)
try_connect() {
  local id=$1 new=$2 name=$3 i st ip
  echo "Connecting to $name..."
  wcli select_network "$id" >/dev/null
  for i in $(seq 1 25); do
    sleep 1
    st=$(wcli status | sed -n 's/^wpa_state=//p')
    [ "$st" = "COMPLETED" ] && break
  done
  if [ "$st" != "COMPLETED" ]; then
    [ "$new" = 1 ] && wcli remove_network "$id" >/dev/null
    wcli enable_network all >/dev/null
    wcli reassociate >/dev/null
    echo "Could not connect to $name. Wrong password? Nothing was saved."
    return 1
  fi
  dhclient -r "$IF" 2>/dev/null; dhclient -nw "$IF" 2>/dev/null
  for i in $(seq 1 15); do ip=$(get_ip); [ -n "$ip" ] && break; sleep 1; done
  wcli enable_network all >/dev/null
  wcli save_config >/dev/null
  chmod 600 "$CONF"
  if [ -n "$ip" ]; then
    echo "Connected to $name (IP $ip). Saved: it connects automatically next time."
  else
    echo "Connected to $name, but got no IP address yet. Saved anyway."
  fi
}

# add a new network and connect; $1 ssid, $2 security, $3 hidden (1/0)
add_and_connect() {
  local ssid=$1 sec=$2 hidden=$3 pw id psk
  if [ "$sec" != "open" ]; then
    while true; do
      read -rsp "Password for $ssid: " pw; echo
      [ -z "$pw" ] && { echo "Cancelled."; return 1; }
      [ ${#pw} -ge 8 ] && [ ${#pw} -le 63 ] && break
      echo "The password must have 8 to 63 characters."
    done
  fi
  id=$(wcli add_network | tail -1)
  wcli set_network "$id" ssid "$(hexstr "$ssid")" >/dev/null
  [ "$hidden" = 1 ] && wcli set_network "$id" scan_ssid 1 >/dev/null
  case "$sec" in
    open) wcli set_network "$id" key_mgmt NONE >/dev/null ;;
    WPA3)
      wcli set_network "$id" key_mgmt SAE >/dev/null
      wcli set_network "$id" ieee80211w 2 >/dev/null
      wcli set_network "$id" sae_password "\"$pw\"" >/dev/null ;;
    *)
      # store the derived key, not the passphrase
      psk=$(wpa_passphrase "$ssid" "$pw" | sed -n 's/^[[:space:]]*psk=\([0-9a-f]\{64\}\)$/\1/p')
      wcli set_network "$id" psk "$psk" >/dev/null ;;
  esac
  wcli enable_network "$id" >/dev/null
  try_connect "$id" 1 "$ssid"
}

conf_get() { sed -n "s/^$1=//p" "$PCONF" 2>/dev/null | tail -1; }
conf_set() {
  touch "$PCONF"
  if grep -q "^$1=" "$PCONF"; then sed -i "s/^$1=.*/$1=$2/" "$PCONF"; else echo "$1=$2" >> "$PCONF"; fi
}
