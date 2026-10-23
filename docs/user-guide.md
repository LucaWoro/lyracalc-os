# LyraCalc OS user guide

- [First boot](#first-boot)
- [Commands](#commands)
- [Keyboard shortcuts](#keyboard-shortcuts)
- [Status bar](#status-bar)
- [Battery](#battery)
- [Settings](#settings)
- [Supported USB adapters](#supported-usb-adapters)
- [Hardware details](#hardware-details)

## First boot

The first boot runs `picocalc-firstboot` once: it grows the root partition to fill the card, creates
SSH host keys and writes the default `/etc/picocalc.conf`.

Then the setup wizard starts on the PicoCalc screen. The first question is whether to use the guide
(`y`) or go straight to the terminal (`n`). In the guide, `y` = yes, `n` = no, `s` or Enter = skip.

1. Password (login is `root` / `root`)
2. Time zone and WiFi country
3. WiFi (if a stick is plugged in), and whether WiFi starts at boot
4. Sound (needs the [sound mod](hardware.md#sound))
5. Bluetooth pairing (if a stick is plugged in)
6. PICO-8 (installs it if a `pico-8_*_raspi.zip` is on the SD card)

| Command | |
|---|---|
| `picocalc-setup` | run the wizard |
| `picocalc-setup wifi` | run one step: `password`, `time`, `wifi`, `audio`, `bt`, `pico8` |
| `picocalc-setup --on` | show the wizard at the next boot |
| `picocalc-setup --off` | do not show it at boot |

## Commands

All commands run as root, on the PicoCalc or over SSH.

### PICO-8 and TIC-80

| Command | |
|---|---|
| `pico8install [zip]` | install PICO-8 from your `pico-8_*_raspi.zip` (looks on the SD card and in `/root`) |
| `pico8` | start PICO-8 |
| `pico8browser` | start PICO-8 in SPLORE, switches WiFi on if needed |
| `pico8stream` | PICO-8 at 128x128 for a PC on the USB network: picture via VNC (port 5900), sound via TCP (port 5901) |
| `tic80 [cart]` | start TIC-80; type `surf` for online carts |

PICO-8 is not included; buy it at [lexaloffle.com](https://www.lexaloffle.com/pico-8.php) and use the
Raspberry Pi download. Carts on the SD card show up as `sd/` (PICO-8: `/mnt/sd/pico8`, TIC-80:
`/mnt/sd/tic80`). TIC-80 keeps its own carts in `/root/tic80`.

In both, Shift+arrows move the mouse pointer, Ctrl+`[` and Ctrl+`]` click.

### Network

| Command | |
|---|---|
| `wifion`, `wifioff` | start or stop WiFi |
| `wifils` | list networks nearby |
| `wifisetup` | pick a network by number and enter the password; saved only if it connects |
| `wificonfig` | menu: status, saved networks, forget, hidden network, preferred network, autostart, country |
| `lan` | USB LAN adapters and phone tethering with link, speed and address |
| `lan restart` | ask for new addresses |

USB LAN adapters and tethered phones get an address by DHCP as soon as they are plugged in.

### Bluetooth

| Command | |
|---|---|
| `bton`, `btoff` | switch Bluetooth on or off |
| `btpair` | search, pick a device by number, pair, trust and connect |
| `btlist` | paired devices |
| `btremove` | remove a paired device |

### Sound

| Command | |
|---|---|
| `audioon`, `audiooff` | unmute or mute (saved); the volume is set with the wheel |
| `audiorestart` | reload the sound driver |

`AUDIO=off` in the settings switches sound off completely (the driver is not loaded after a reboot).

### Files, fonts, apps

| Command | |
|---|---|
| `files` | Midnight Commander, SD card on the left, PICO-8 carts on the right |
| `sdeject` | unmount the card in the PicoCalc SD slot |
| `font` | list the console fonts and try one (goes back after 15 s unless you keep it) |
| `font NAME` | switch to a font and save it |
| `apps` | app installer: curated list by category, or any Ubuntu package |
| `ref [topic] [word]` | offline cheat sheets: python, lua, c, cpp, bash, make, git, sed, awk, markdown, vim, pico8, tic80 |
| `overlay` | show or hide the status bar |
| `inputconfig` | mouse speed and key repeat |
| `picocalc-config` | edit the settings file |

In `files`: Tab = other side, F5 copy, F6 move, F8 delete, F10 quit, Ctrl+\ bookmarks. Esc followed by a
number works as the F key with that number.

| Font | Characters |
|---|---|
| default | 40x20 |
| vga8 | 40x40 |
| terminus12 | 53x26 |
| fixed13 | 45x24 |
| terminus14 | 40x22 |
| terminus16, terminus16bold | 40x20 |
| terminus20 | 32x16 |
| terminus24 | 26x13 |
| terminus32 | 20x10 |

The app list is `/usr/local/lib/picocalc/apps.list` (`category|package|description`).

### Coding

micro checks the code on every save and marks errors next to the line (micro linter plugin):

| Language | Checker |
|---|---|
| Bash | shellcheck |
| Lua (PICO-8, TIC-80) | luacheck, knows the PICO-8 and TIC-80 functions |
| Python | pyflakes |
| C, C++ | cppcheck |

luacheck reads standard Lua only. For PICO-8, keep the code in a `.lua` file pulled in with
`#include` and avoid the PICO-8 shorthands there.

`ref python while` opens the Python cheat sheet at the first mention of "while". The cheat sheets come
from [Learn X in Y minutes](https://learnxinyminutes.com) (CC BY-SA 3.0). Man pages are not installed.

### ESP32 and MicroPython

| Command | |
|---|---|
| `esp-flash [file.bin]` | flash MicroPython to an ESP32 on USB; without a file the right firmware for the chip is used |
| `esp` | MicroPython prompt (mpremote), Ctrl+X to leave |
| `esp-run file.py` | run a file on the ESP32 without saving it |
| `esp-up file.py` | save a file as `main.py` and reset |
| `esp-ls` | list the files on the ESP32 |

Firmware files are in `/usr/local/share/lyracalc/esp-firmware`; newer ones can be put into `~/esp/firmware`.

## Keyboard shortcuts

| Keys | Where | |
|---|---|---|
| Alt+O | everywhere | show or hide the status bar (needs the [STM32 patch](../firmware/stm32)) |
| Alt+G | PICO-8 | game mode on or off |
| Shift+arrows | PICO-8, TIC-80 | move the mouse pointer |
| Ctrl+[ , Ctrl+] | PICO-8, TIC-80 | right and left click |

Game mode turns the keyboard into a PICO-8 controller: `[` and `]` are the two action buttons, and
keys that could pause or quit the game (P, O, I, X, C, Z, V, N, M, Del, End) are ignored. Enter still
opens the pause menu. Game mode is off when PICO-8 starts and is switched off when it ends.

The keyboard driver releases a key that the keyboard has not reported for 500 ms, so keys do not
stick when a release event is lost.

## Status bar

Alt+O or `overlay` shows a bar on the top 11 pixel rows. It is drawn by the display driver, so it stays
on top of the console, PICO-8 and TIC-80.

FPS, CPU (total and one bar per core), RAM, SD card MB/s, WiFi, sound, temperature, battery.

| Icon | Look | Meaning |
|---|---|---|
| WiFi | green | connected, arcs = signal |
| WiFi | yellow | on, not connected |
| WiFi | grey | off |
| WiFi | red x | no stick |
| Sound | green waves | on |
| Sound | red x | muted |
| Sound | red slash | sound off or no driver |
| Battery | yellow frame | charging |

`OVERLAY=on` shows the bar at boot.

## Battery

`picocalc-battery` checks the battery every 5 seconds:

| Level | Default | |
|---|---|---|
| `BATTERY_WARN` | 15 % | orange message in the status bar for 8 s, again every 2 minutes |
| `BATTERY_CRITICAL` | 5 % | red message, blinking all the time |
| `BATTERY_SHUTDOWN` | 3 % | 60 s countdown, then a clean shutdown |

The messages also show while the status bar is hidden and inside PICO-8 and TIC-80. The shutdown
countdown is also announced on every open terminal. Plugging in the charger cancels them. Charging over the Lyra USB port is not visible to
the keyboard controller; in that case only a rising level cancels the countdown.

## Settings

All settings are in `/etc/picocalc.conf` (`KEY=value`). The commands above change it for you;
`picocalc-config` opens it in an editor and applies it on exit. `picocalc-apply` applies it by hand,
`picocalc-apply ssh audio` only some parts (`system wifi ssh bt audio screen input`).

The file is applied at every boot, so a host name or time zone changed elsewhere is set back.
Passwords, WiFi keys, SSH keys and Bluetooth pairings are not stored here.

| Key | Values (default) | Also with |
|---|---|---|
| `HOSTNAME` | device name (`lyra`) | |
| `TIMEZONE` | e.g. `Europe/Berlin` (`UTC`) | setup wizard |
| `SETUP_WIZARD` | `on` / `off` | `picocalc-setup --on/--off` |
| `WIFI_AUTOSTART` | `on` / `off` (`off`) | `wificonfig` |
| `WIFI_COUNTRY` | two letters, e.g. `DE` | `wificonfig`, setup wizard |
| `SSH` | `on` / `off` (`on`) | |
| `SSH_PASSWORD` | `on` / `off` = keys only (`on`) | |
| `BT_AUTOSTART` | `on` / `off` (`off`) | |
| `AUDIO` | `on` / `off` (`on`), reboot | |
| `AUDIO_MUTE` | `on` / `off` (`off`) | `audioon`, `audiooff` |
| `AUDIO_STANDBY_MS` | 0 to 60000 (`2000`) | |
| `CONSOLE_FONT` | font name (`default`) | `font` |
| `OVERLAY` | status bar at boot, `on` / `off` (`off`) | Alt+O |
| `BATTERY_ALERTS` | `on` / `off` (`on`) | |
| `BATTERY_WARN` | percent (`15`) | |
| `BATTERY_WARN_SECONDS` | seconds (`8`) | |
| `BATTERY_WARN_REPEAT` | seconds (`120`) | |
| `BATTERY_CRITICAL` | percent (`5`) | |
| `BATTERY_AUTO_SHUTDOWN` | `on` / `off` (`on`) | |
| `BATTERY_SHUTDOWN` | percent (`3`) | |
| `BATTERY_SHUTDOWN_DELAY` | seconds (`60`) | |
| `MOUSE_SPEED` | 1 to 10 (`2`) | `inputconfig` |
| `KEY_REPEAT_DELAY` | 250 to 1000 ms (`400`) | `inputconfig` |
| `KEY_REPEAT_RATE` | 2 to 30 per second (`15`) | `inputconfig` |
| `USB_KEYBOARD_LAYOUT` | layout for USB keyboards, e.g. `de` (`us`) | |
| `USB_KEYBOARD_VARIANT` | e.g. `nodeadkeys` (empty) | |

The PicoCalc keyboard always uses the US layout. While a USB keyboard with another
`USB_KEYBOARD_LAYOUT` is plugged in, the console switches to that layout; in PICO-8 and TIC-80 only the
USB keyboard uses it.

Other files:

| File | |
|---|---|
| `/etc/wpa_supplicant.conf` | saved WiFi networks |
| `/etc/lyracalc-release` | name and version shown on the info screen |
| `/root/.lexaloffle/pico-8/config.txt` | PICO-8 settings |

## Supported USB adapters

Tested on the PicoCalc: TP-Link Archer TX20U, TP-Link Archer TX10UB Nano (WiFi only), a generic
RTL8188EUS nano stick and the TP-Link UB400 (Bluetooth). The other drivers are included but not tested.

### WiFi

| Chipset | Example | Driver |
|---|---|---|
| RTL8852BU / 8832BU | TP-Link Archer TX20U | 8852bu |
| RTL8851BU | TP-Link Archer TX10UB Nano | 8851bu |
| RTL8188EUS | 150 Mbit nano sticks | 8188eu |
| RTL8821CU / 8811CU | AC600 nano sticks | 8821cu |
| RTL8812BU / 8822BU | AC1200 sticks | 88x2bu |
| RTL8821AU / 8811AU | AC600 sticks | 8821au |
| RTL8812AU | AC1200 sticks | 8812au |
| RTL8188CU, 8192CU/EU, 8723BU | older Realtek sticks | rtl8xxxu |
| MT7601U | 150 Mbit sticks | mt7601u |
| MT7610U / MT7612U | AC600 / AC1200 sticks | mt76x0u, mt76x2u |
| MT7921AU | AXE3000 sticks | mt7921u |
| RT2870 / RT3070 / RT5370 | Ralink sticks | rt2800usb |
| AR9271 | TP-Link TL-WN722N v1 | ath9k_htc |

### Bluetooth

CSR8510 (TP-Link UB400), Realtek and MediaTek adapters with btusb.

### Wired

RTL8152/8153/8156 (r8152), ASIX AX88772/AX88179, Microchip LAN7800, SMSC LAN95xx, Davicom DM9601,
CoreChip SR9700, CDC Ethernet/EEM/NCM adapters, Android tethering (rndis_host, cdc_ncm), iPhone
tethering (ipheth).

## Hardware details

### Keyboard

The STM32 keyboard repeats a held key about every 110 ms; the driver ignores these repeats and uses
the Linux key repeat instead. Driver parameters: `/sys/module/picocalc_kbd/parameters/p_mouse` and
`p_game`. `/sys/firmware/picocalc/` has `battery_percent` (bit 7 = charging), `keyboard_backlight`,
`screen_backlight`, `power_off` and `last_keypress`.

### Display

ILI9488 at 100 MHz SPI. The driver provides `/dev/fb_overlay` for the status bar.

### Second SD slot

| Signal | Pin |
|---|---|
| MOSI | RMIO28 |
| CLK | RMIO29 |
| CS | RMIO30 |
| MISO | RMIO31 |
| Card detect | GPIO1_B2, active low |

`mmc_spi` on SPI1 at up to 50 MHz, the card is `/dev/mmcblk1`. FAT32, ext4 and NTFS cards are mounted
at `/mnt/sd`. A shutdown hook unloads `mmc_spi`, otherwise a card left in SPI mode stops the reboot.

### Lyra USB-C port

The port starts as a USB device (network link to the PC, the Lyra is `192.168.123.100`). It can switch to
host mode with `echo host > /sys/devices/platform/ff2b0000.usb2-phy/otg_mode` (back: `peripheral`). The
Lyra does not supply 5 V on this port, so devices need a powered hub or an OTG Y-cable.
