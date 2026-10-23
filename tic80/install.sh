#!/bin/bash
# Install a TIC-80 binary built with build.sh (start it with: tic80)
#   install.sh [path/to/tic80]
set -e
D=$(cd "$(dirname "$0")" && pwd)
BIN=${1:-$D/tic80}
[ "$(id -u)" = 0 ] || { echo "Run as root."; exit 1; }
[ -f "$BIN" ] || { echo "TIC-80 binary not found: $BIN"; exit 1; }
install -D -m 755 "$BIN" /usr/local/lib/tic80/tic80
mkdir -p /usr/local/share/doc/tic80
cp "$D"/licenses/*.txt /usr/local/share/doc/tic80/
ldconfig -p | grep -q 'libcurl.so.4 ' || apt-get install -y libcurl4t64 || echo "libcurl missing: surf will not work"
if ldd /usr/local/lib/tic80/tic80 | grep -q 'not found'; then
  ldd /usr/local/lib/tic80/tic80 | grep 'not found'
else
  echo "TIC-80 installed"
fi
