#!/bin/bash
# Install or update the LyraCalc OS userland on a PicoCalc with a Luckfox Lyra.
# Needs the patched kernel from kernel/ (or a LyraCalc OS image).
#
#   sudo ./install.sh                 packages + files + services
#   sudo ./install.sh --no-packages   skip apt
set -e
cd "$(dirname "$(readlink -f "$0")")"
[ "$(id -u)" = 0 ] || { echo "Run as root."; exit 1; }
[ -d rootfs ] || { echo "rootfs/ not found."; exit 1; }

PKG=1
for a in "$@"; do
  case "$a" in
    --no-packages) PKG=0 ;;
    -h|--help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $a"; exit 1 ;;
  esac
done

VERSION=$(cat VERSION)
MP_VERSION=v1.29.0
MP_DATE=20260824
MP_BOARDS="ESP32_GENERIC ESP32_GENERIC_S2 ESP32_GENERIC_S3 ESP32_GENERIC_C3 ESP32_GENERIC_C6"

step() { echo "== $* =="; }

if [ "$PKG" = 1 ]; then
  step "Packages"
  mapfile -t P < <(grep -v '^#' packages.txt | grep .)
  MISSING=()
  for p in "${P[@]}"; do
    dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q "install ok installed" || MISSING+=("$p")
  done
  if [ ${#MISSING[@]} -gt 0 ]; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${MISSING[@]}"
  fi
  command -v mpremote >/dev/null || pip3 install --break-system-packages -q mpremote || echo "mpremote not installed"
fi

step "Files"
rm -rf /usr/local/bin/__pycache__
cp -r rootfs/. /
( cd rootfs && find usr/local/bin usr/local/sbin usr/lib/systemd/system-shutdown etc/update-motd.d etc/X11/xinit -type f ) |
  while read -r f; do chmod 755 "/$f"; done
chmod 700 /root

step "Settings"
python3 - /usr/local/share/lyracalc/picocalc.conf.default /etc/picocalc.conf << 'PY'
import os, re, sys
tpl, conf = sys.argv[1:3]
old = {}
if os.path.exists(conf):
    for line in open(conf):
        m = re.match(r"^([A-Z][A-Z0-9_]*)=(.*)$", line.rstrip("\n"))
        if m:
            old[m.group(1)] = m.group(2)
out, seen = [], set()
for line in open(tpl):
    m = re.match(r"^([A-Z][A-Z0-9_]*)=(.*)$", line.rstrip("\n"))
    if m and m.group(1) in old:
        line = "%s=%s\n" % (m.group(1), old[m.group(1)])
    if m:
        seen.add(m.group(1))
    out.append(line)
extra = [k for k in old if k not in seen]
if extra:
    out.append("\n# ----- Other ----------------------------------------------------------\n")
    out += ["%s=%s\n" % (k, old[k]) for k in extra]
open(conf, "w").write("".join(out))
PY

step "Release info"
sed -i "s/^LC_VERSION=.*/LC_VERSION=\"$VERSION\"/" /etc/lyracalc-release
rm -f /etc/os-release
cat > /etc/os-release << EOF
PRETTY_NAME="LyraCalc OS $VERSION"
NAME="LyraCalc OS"
VERSION_ID="24.04"
VERSION="$VERSION (Ubuntu 24.04 LTS)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
UBUNTU_CODENAME=noble
EOF
for f in 00-header 10-help-text 50-motd-news 60-unminimize 91-contract-ua-esm-status 91-release-upgrade; do
  [ -f "/etc/update-motd.d/$f" ] && chmod -x "/etc/update-motd.d/$f"
done

step "ESP32 firmware"
D=/usr/local/share/lyracalc/esp-firmware
mkdir -p "$D"
cp -n /root/esp/firmware/*.bin "$D"/ 2>/dev/null || true
for b in $MP_BOARDS; do
  f=$b-$MP_DATE-$MP_VERSION.bin
  ls "$D/$b"-[0-9]*.bin >/dev/null 2>&1 && continue
  curl -fsSL --max-time 120 -o "$D/$f" "https://micropython.org/resources/firmware/$f" 2>/dev/null || rm -f "$D/$f"
done
ls "$D" | sed 's/^/  /'

step "Services"
systemctl daemon-reload
for u in picocalc-firstboot picocalc-font picocalc-overlay picocalc-apply picocalc-battery \
         picocalc-setup-wizard printk-quiet zram; do
  systemctl enable "$u.service" >/dev/null 2>&1
done
udevadm control --reload-rules 2>/dev/null || true
systemctl restart picocalc-overlay.service picocalc-battery.service 2>/dev/null || true
/usr/local/sbin/picocalc-apply

[ -x /usr/local/lib/tic80/tic80 ] || echo "TIC-80 is not installed, see tic80/README.md"
echo ""
echo "LyraCalc OS $VERSION installed."
