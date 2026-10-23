# Read and write /etc/picocalc.conf (KEY=value lines)
PCONF=/etc/picocalc.conf
pc_get() { sed -n "s/^$1=//p" "$PCONF" 2>/dev/null | tail -1; }
pc_set() {
  touch "$PCONF"
  if grep -q "^$1=" "$PCONF"; then sed -i "s|^$1=.*|$1=$2|" "$PCONF"; else echo "$1=$2" >> "$PCONF"; fi
}
