# TIC-80

[TIC-80](https://tic80.com) v1.1.2837 (free version) cross-built for Ubuntu 24.04 armhf.
SDL2 is linked statically, X11 and ALSA are loaded at runtime, no OpenGL.

| Patch | |
|---|---|
| 0001 | fix an unaligned read at startup (bus error on ARM) |
| 0002 | `TIC80_WINDOW=WxH`: window of exactly this size at 0,0, picture scaled to fit |
| 0003 | `TIC80_NOBORDER=1`: picture without the border |

```sh
./build.sh                  # on an x86_64 Ubuntu 24.04 PC, result: ~/tic80-build/tic80
sudo ./install.sh tic80     # on the PicoCalc
```

The `tic80` command in `rootfs/usr/local/bin` starts it full screen on the PicoCalc.

TIC-80 is MIT licensed, Copyright (c) 2017 Vadim Grigoruk. The licences of TIC-80 and the libraries it
includes are in [licenses](licenses).
