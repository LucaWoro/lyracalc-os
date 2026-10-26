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
> - **Known bug:** after the PicoCalc was off for several hours, the speakers can hiss after boot and the
>   noise does not stop. Until this is fixed, turn the volume wheel down or set `AUDIO=off`.

## Features

- Console UI made for the 320x320 screen: login picture, info screen with IP addresses, selectable fonts
- Status bar (Alt+O) with FPS, CPU, RAM, SD speed, WiFi, sound, temperature and battery, drawn by the display driver so it never flickers
- Battery warnings in the status bar and automatic shutdown when the battery is empty
- PICO-8 (bring your own copy) with keyboard mouse and a game mode for the PicoCalc keys
- TIC-80 (free version) built for the Lyra
- USB WiFi sticks (Realtek, MediaTek, Ralink, Atheros), Bluetooth, USB LAN adapters and phone tethering
- Simple commands for everything: `wifisetup`, `btpair`, `audioon`, `files`, `apps`, `ref`, ...
- Second SD card slot with automount
- Sound driver with standby and soft fades (needs a hardware mod)
- One settings file, `/etc/picocalc.conf`, and a setup wizard on first boot
- Developer tools: micro with linters for Bash, Lua, Python and C, offline cheat sheets, ESP32 / MicroPython flashing

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

- After several hours off, the speakers can hiss after boot and keep hissing (with the sound mod). Turn the volume down or set `AUDIO=off`.
- Charging over the Lyra USB port is not visible to the keyboard controller, so the battery icon shows no charging sign.
- The Lyra does not supply 5 V on its USB-C port. USB devices need a powered hub or an OTG Y-cable.
- Many WiFi chipsets are built in but not tested yet. Reports are welcome.
- The Bluetooth part of the RTL8851BU (TP-Link TX10UB) does not work yet.

## Credits and licence

LyraCalc OS builds on the work of many people, see [CREDITS.md](CREDITS.md).

The scripts and files in this repository are MIT licensed ([LICENSE](LICENSE)), except where a file or
folder says otherwise: the kernel patches are GPL-2.0, the keyboard firmware patch is LGPL-3.0, TIC-80 is MIT (see [tic80/licenses](tic80/licenses)),
the cheat sheets in `rootfs/usr/local/share/lyracalc/ref` are CC BY-SA 3.0.

PICO-8 is commercial software by Lexaloffle and is not included.
"Ubuntu" is a trademark of Canonical Ltd. LyraCalc OS is not affiliated with Canonical, ClockworkPi or Luckfox.
