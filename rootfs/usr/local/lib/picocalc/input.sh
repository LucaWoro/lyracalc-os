# Input settings from /etc/picocalc.conf, clamped to safe limits
in_get() { sed -n "s/^$1=//p" /etc/picocalc.conf 2>/dev/null | tail -1; }
in_num() { local v; v=$(in_get "$1"); [[ "$v" =~ ^[0-9]+$ ]] || v=$2; [ "$v" -lt "$3" ] && v=$3; [ "$v" -gt "$4" ] && v=$4; echo "$v"; }
MOUSE_SPEED=$(in_num MOUSE_SPEED 2 1 10)
KEY_REPEAT_DELAY=$(in_num KEY_REPEAT_DELAY 400 250 1000)
KEY_REPEAT_RATE=$(in_num KEY_REPEAT_RATE 15 2 30)
