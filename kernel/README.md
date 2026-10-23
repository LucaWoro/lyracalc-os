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

| Driver | Source |
|---|---|
| 8852bu | [morrownr/rtl8852bu-20250826](https://github.com/morrownr/rtl8852bu-20250826) |
| 8851bu | [fofajardo/rtl8851bu](https://github.com/fofajardo/rtl8851bu) |
| 8821cu | [morrownr/8821cu-20210916](https://github.com/morrownr/8821cu-20210916) |
| 88x2bu | [morrownr/88x2bu-20210702](https://github.com/morrownr/88x2bu-20210702) |
| 8821au | [morrownr/8821au-20210708](https://github.com/morrownr/8821au-20210708) |
| 8812au | [morrownr/8812au-20210820](https://github.com/morrownr/8812au-20210820) |
| 8188eu | [aircrack-ng/rtl8188eus](https://github.com/aircrack-ng/rtl8188eus) |

The patches are GPL-2.0, like the files they change.
