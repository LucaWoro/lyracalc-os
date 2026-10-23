# Building LyraCalc OS

LyraCalc OS is the Ubuntu 24.04 image from the
[markbirss SDK](https://github.com/markbirss/rk3506-ubuntu-luckfox-lyra-w-picocalc) with a patched
kernel and the files from this repository on top.

You need an x86_64 Linux PC (Ubuntu 24.04 works) for the kernel and TIC-80, and a PicoCalc with a
Lyra for the rest.

## 1. Base system

Build and flash the Ubuntu image as described in the SDK README. The kernel build below uses the
same SDK checkout, so do the full SDK setup (toolchain, board selection) first.

## 2. Kernel, modules, WiFi drivers

```sh
cd kernel
./build.sh ~/rk3506-ubuntu-luckfox-lyra-w-picocalc
```

The script applies `kernel/patches` to the SDK (tested on commit `dbacba7e`), builds the kernel with
the SDK build script, adds the Realtek vendor WiFi drivers and the firmware from linux-firmware, and
writes `kernel/out/lyracalc-kernel-<version>.tgz`.

Copy the pack and `install-kernel.sh` to the PicoCalc and run:

```sh
sudo ./install-kernel.sh lyracalc-kernel-6.1.99.tgz
sudo reboot
```

## 3. LyraCalc OS files

On the PicoCalc, with a network connection:

```sh
git clone https://github.com/LucaWoro/lyracalc-os
cd lyracalc-os
sudo ./install.sh
```

`install.sh` installs the packages from `packages.txt`, copies `rootfs/` to `/`, merges new keys into
`/etc/picocalc.conf` (existing values are kept), downloads the MicroPython firmware for `esp-flash` and
enables the services. It can be run again after a `git pull`.

## 4. TIC-80

```sh
cd tic80
./build.sh            # on the PC, result: ~/tic80-build/tic80
```

Copy the `tic80` folder and the binary to the PicoCalc and run `sudo ./install.sh /path/to/tic80`.

## 5. Keyboard firmware

Optional, needed for Alt+O. See [firmware/stm32](../firmware/stm32).

## 6. Release image

On a Linux PC with the PicoCalc card in a USB card reader:

```sh
sudo tools/make-release-image.sh
```

The card is only read. The script copies the system into a new image that is only as big as the
content, removes private data (WiFi networks, PICO-8, `/root`, SSH host keys, logs, Bluetooth pairings),
resets the settings and the root password (`root`), switches the setup wizard on and compresses the
result to `~/lyracalc-release/lyracalc-os-<version>.img.xz`. Test it on a spare card before publishing.
