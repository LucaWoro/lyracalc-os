# LyraCalc OS

A small Linux distribution for the [ClockworkPi PicoCalc](https://www.clockworkpi.com/picocalc) with a
[Luckfox Lyra](https://wiki.luckfox.com/Luckfox-Lyra/) (RK3506G2) core board. It is based on Ubuntu 24.04
(armhf) and the Luckfox vendor kernel 6.1, and turns the PicoCalc into a pocket terminal for coding,
tinkering and PICO-8 / TIC-80 games.

**Status: 0.7.0-beta.** Daily use works, but expect rough edges. Bug reports are welcome.

> **Before you start**
>
> - **Sound needs a hardware mod on the Lyra** (one 0 Ω resistor removed, one wire bridge), see
>   [docs/hardware.md](docs/hardware.md). Without it the speakers stay silent; set `AUDIO=off`.
> - **Use at your own risk.** No warranty and no liability for damage to hardware, batteries or data,
>   especially when flashing the keyboard firmware or soldering. See [DISCLAIMER.md](DISCLAIMER.md).
> - **Known bug (sound mod):** while booting, the speakers can crackle or hiss loudly. **Turn the volume
>   wheel down before switching the PicoCalc on.** After the PicoCalc was off for several hours, the hiss
>   can also stay after boot; then keep the volume down or set `AUDIO=off`. A fix is planned.

## Features

- Console UI made for the 320x320 screen: login picture, info screen with IP addresses, selectable fonts
- Status bar (Alt+O) with FPS, CPU, RAM, SD speed, WiFi, sound, temperature and battery, drawn by the display driver so it never flickers
- Battery warnings in the status bar and automatic shutdown when the battery is empty
- PICO-8 (bring your own copy) with keyboard mouse (Shift+arrows) and a game mode for the PicoCalc keys (Alt+G)
- TIC-80 (free version) built for the Lyra
- USB WiFi sticks (Realtek, MediaTek, Ralink, Atheros), Bluetooth, USB LAN adapters and phone tethering,
  see the [supported adapters](docs/user-guide.md#supported-usb-adapters)
- USB and Bluetooth keyboards and mice, with a layout setting for USB keyboards and a mouse pointer in the console
- Keyboard driver fixes: no more stuck keys, both Shift keys work, key repeat and mouse speed adjustable
- Simple commands for everything: `wifisetup`, `btpair`, `audioon`, `files`, `apps`, `ref`, ...
- Second SD card slot with automount
- Sound driver with standby and soft fades (needs a hardware mod)
- One settings file, `/etc/picocalc.conf`, and a setup wizard on first boot
- Developer tools: micro with syntax highlighting and error checking on save (Bash, Lua, Python, C/C++),
  offline cheat sheets, ESP32 / MicroPython flashing
- SSH and a USB network link to the PC out of the box
- The PicoCalc switches itself off after `poweroff`; compressed swap in RAM (zram)

## Hardware

| Part | Notes |
|---|---|
| ClockworkPi PicoCalc | |
| Luckfox Lyra | RK3506G2 version |
| microSD card | 16 GB or more |
| USB WiFi stick | optional, see the [supported sticks](docs/user-guide.md#supported-usb-adapters) |
| LyraCalc keyboard firmware | optional, needed for Alt+O, see [firmware/stm32](firmware/stm32) |
| Sound mod | needed for sound, see [docs/hardware.md](docs/hardware.md) |

## Install

1. Download `lyracalc-os-<version>.img.xz` from the [Releases](../../releases) page.
2. Write it to a microSD card with [balenaEtcher](https://etcher.balena.io/), Raspberry Pi Imager
   ("Use custom") or `xzcat lyracalc-os-*.img.xz | sudo dd of=/dev/sdX bs=4M conv=fsync`.
3. Put the card into the Lyra and switch the PicoCalc on.

The first boot grows the filesystem to the size of the card and creates new SSH keys. Then the setup
wizard starts (password, time zone, WiFi, sound, Bluetooth, PICO-8). Every step can be skipped.

Login: `root` / `root`. Change it with `passwd` or in the setup wizard.

Over USB the Lyra shows up as a network device on the PC; SSH to `root@192.168.123.100`.

## Usage

| Command | |
|---|---|
| `picocalc-setup` | setup wizard |
| `picocalc-config` | edit all settings |
| `wifisetup`, `wificonfig` | connect to WiFi, WiFi settings |
| `btpair` | pair a Bluetooth device |
| `pico8install`, `pico8` | install and start PICO-8 |
| `tic80` | start TIC-80 |
| `files` | file manager |
| `apps` | install more software |
| `ref` | offline cheat sheets |

All commands and settings are described in the [user guide](docs/user-guide.md).

## Building

The image is made of four parts, each with its own folder:

| Folder | Content |
|---|---|
| [kernel](kernel) | patches for the Luckfox SDK kernel (display, keyboard, sound, SD slot, USB) and a build script |
| [rootfs](rootfs) | the LyraCalc OS files, installed with [install.sh](install.sh) |
| [tic80](tic80) | TIC-80 patches and cross-build script |
| [firmware/stm32](firmware/stm32) | patch for the PicoCalc keyboard firmware |
| [tools](tools) | script that makes a release image from an SD card |

See [docs/building.md](docs/building.md).

## Known issues

- With the sound mod, the speakers can crackle or hiss loudly while booting; turn the volume down before switching on. After several hours off, the hiss can stay after boot; keep the volume down or set `AUDIO=off`.
- Charging over the Lyra USB port is not visible to the keyboard controller, so the battery icon shows no charging sign.
- The Lyra does not supply 5 V on its USB-C port. USB devices need a powered hub or an OTG Y-cable.
- Many WiFi chipsets are built in but not tested yet. Reports are welcome.
- The Bluetooth part of the RTL8851BU (TP-Link TX10UB) does not work yet.

## Disclaimer

LyraCalc OS is provided "as is", without warranty of any kind. You use the software, the firmware and
the hardware instructions at your own risk; the authors are not liable for any damage. Details:
[DISCLAIMER.md](DISCLAIMER.md).

## Credits and licence

LyraCalc OS builds on the work of many people, see [CREDITS.md](CREDITS.md).

The scripts and files in this repository are MIT licensed ([LICENSE](LICENSE)), except where a file or
folder says otherwise: the kernel patches are GPL-2.0, the keyboard firmware patch is LGPL-3.0, TIC-80 is MIT (see [tic80/licenses](tic80/licenses)),
the cheat sheets in `rootfs/usr/local/share/lyracalc/ref` are CC BY-SA 3.0.

If you build on LyraCalc OS, a mention and a link back to this repository are appreciated.

PICO-8 is commercial software by Lexaloffle and is not included.
"Ubuntu" is a trademark of Canonical Ltd. LyraCalc OS is not affiliated with Canonical, ClockworkPi or Luckfox.
