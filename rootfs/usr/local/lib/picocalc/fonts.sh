# Console fonts: name -> /usr/share/consolefonts/<file>.psf.gz
FONTS="default vga8 terminus12 fixed13 terminus14 terminus16 terminus16bold terminus20 terminus24 terminus32"
FONTDIR=/usr/share/consolefonts
font_file() {
  case "$1" in
    default)        echo Uni2-VGA16 ;;
    vga8)           echo Uni2-VGA8 ;;
    terminus12)     echo Uni2-Terminus12x6 ;;
    fixed13)        echo Uni2-Fixed13 ;;
    terminus14)     echo Uni2-Terminus14 ;;
    terminus16)     echo Uni2-Terminus16 ;;
    terminus16bold) echo Uni2-TerminusBold16 ;;
    terminus20)     echo Uni2-Terminus20x10 ;;
    terminus24)     echo Uni2-Terminus24x12 ;;
    terminus32)     echo Uni2-Terminus32x16 ;;
  esac
}
font_get() { sed -n 's/^CONSOLE_FONT=//p' /etc/picocalc.conf 2>/dev/null | tail -1; }
font_apply() {
  local f; f=$(font_file "$1"); [ -n "$f" ] || return 1
  setfont -C /dev/tty1 "$FONTDIR/$f.psf.gz"
}
