# Kernel

Patches for the Luckfox SDK kernel (Linux 6.1.99) in
[markbirss/rk3506-ubuntu-luckfox-lyra-w-picocalc](https://github.com/markbirss/rk3506-ubuntu-luckfox-lyra-w-picocalc),
commit `dbacba7e`.

| Patch | |
|---|---|
| 0001 | ILI9488: `/dev/fb_overlay` for the status bar, 150 fps refresh, 100 MHz SPI, no noise at power-on |
| 0002 | keyboard: mouse keys, PICO-8 game mode, power off after shutdown, stuck key release, Alt+O |
| 0003 | sound: standby, soft fades, mute parameter, pin held low at boot |
| 0004 | second SD slot on SPI1 |
| 0005 | USB-C port in OTG mode |
| 0006 | USB WiFi, Bluetooth, LAN and serial drivers, zram, snd-aloop |

`build.sh` applies the patches, builds the kernel and modules, the Realtek vendor drivers below and
collects the firmware listed in `firmware.txt`. `install-kernel.sh` installs the result on the PicoCalc.

| Driver | Source | Commit |
|---|---|---|
| 8852bu | [morrownr/rtl8852bu-20250826](https://github.com/morrownr/rtl8852bu-20250826) | [`b6a299b4fe95`](https://github.com/morrownr/rtl8852bu-20250826/tree/b6a299b4fe95cb6a37eec27a6c3b21cbaa6abfa8) |
| 8851bu | [fofajardo/rtl8851bu](https://github.com/fofajardo/rtl8851bu) | [`9e37e7a11013`](https://github.com/fofajardo/rtl8851bu/tree/9e37e7a1101316a05d5daede91549ea779b64539) |
| 8821cu | [morrownr/8821cu-20210916](https://github.com/morrownr/8821cu-20210916) | [`bda65aac150d`](https://github.com/morrownr/8821cu-20210916/tree/bda65aac150d2cde0df9603206eec23a6f3b77c4) |
| 88x2bu | [morrownr/88x2bu-20210702](https://github.com/morrownr/88x2bu-20210702) | [`d31ffa827bb9`](https://github.com/morrownr/88x2bu-20210702/tree/d31ffa827bb95b8a436c2a469b5163b634ac4333) |
| 8821au | [morrownr/8821au-20210708](https://github.com/morrownr/8821au-20210708) | [`1a819991f5b7`](https://github.com/morrownr/8821au-20210708/tree/1a819991f5b75e64dfcf922b96a6681f367cbba0) |
| 8812au | [morrownr/8812au-20210820](https://github.com/morrownr/8812au-20210820) | [`4722250273e4`](https://github.com/morrownr/8812au-20210820/tree/4722250273e4316daf9d8688e9916ea94c36a5ff) |
| 8188eu | [aircrack-ng/rtl8188eus](https://github.com/aircrack-ng/rtl8188eus) | [`af3bf004458f`](https://github.com/aircrack-ng/rtl8188eus/tree/af3bf004458f76b7aec33e9ba552cd382ed1f5c3) |

The patches are GPL-2.0, like the files they change.
