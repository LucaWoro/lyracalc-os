# PicoCalc keyboard firmware

LyraCalc OS uses the PicoCalc keyboard firmware [picocalc_BIOS](https://git.jcsmith.fr/jackcartersmith/picocalc_BIOS)
(a rewrite of the original ClockworkPi firmware, commit `1b649c8`) with one small patch:

- Alt+O sends the key code `0xE1`, which the LyraCalc OS keyboard driver reports as `KEY_PROG1`
  (show and hide the status bar)
- right Shift is reported as left Shift

LyraCalc OS works without it; only Alt+O is missing (the `overlay` command still works).

## Download

Every [release](../../../releases) has the ready-made firmware (`lyracalc-picocalc-bios-<version>.bin`) and
the complete source it was built from (`lyracalc-picocalc-bios-<version>-source.tar.gz`).

## Flashing

> **At your own risk.** A failed or wrong flash can leave the keyboard controller, and with it the whole
> PicoCalc, unusable. The keyboard controller also handles battery charging and power. Only flash if you
> can restore a working firmware (for example the original ClockworkPi firmware). There is no warranty
> and no liability for any damage, see [DISCLAIMER.md](../../DISCLAIMER.md).

You need a computer with [STM32CubeProgrammer](https://www.st.com/en/development-tools/stm32cubeprog.html)
(free, Windows, macOS, Linux), a USB-C cable and a small screwdriver.

### 1. Prepare the PicoCalc

1. Switch the PicoCalc off and take out both batteries.
2. Open the case.
3. On the mainboard, find the DIP switch **SW701** and set switch **1 to ON**. This starts the keyboard
   controller in its flashing mode.
4. Connect the **PicoCalc USB-C port** (not the one on the Lyra) to the computer and press the power
   button. The screen stays dark; that is normal.

### 2. Connect STM32CubeProgrammer

1. Start STM32CubeProgrammer.
2. On the right, choose **UART** instead of ST-LINK.
3. Port: the new COM port of the PicoCalc (Windows: `COM3`, `COM4`, ...; Linux: `/dev/ttyUSB0`).
   Leave the other settings as they are (baud rate 115200, parity Even).
4. Click **Connect**. The log at the bottom shows the connected device (STM32F103).

### 3. Back up the current firmware

1. Open **Memory & File editing** (the first icon on the left).
2. Click **Read**, then the arrow next to it, **Save As...**, and save the file, for example as
   `picocalc-firmware-backup.bin`.

With this file you can always go back to the firmware you had.

### 4. Flash the LyraCalc firmware

1. Open **Erasing & Programming** (the second icon on the left).
2. File path: choose `lyracalc-picocalc-bios-<version>.bin`.
3. Start address: `0x08000000`.
4. Tick **Verify programming**.
5. Click **Start Programming** and wait for "File download complete" and the successful verification.
6. Click **Disconnect**.

### 5. Back to normal

1. Unplug the USB cable.
2. Set switch **1 of SW701 back to OFF**. If you forget this, the PicoCalc will not start normally.
3. Close the case, put the batteries back and switch the PicoCalc on.
4. Test: Alt+O shows and hides the status bar in LyraCalc OS.

To go back to your old firmware, repeat the steps and flash your backup file instead.

## Building

```sh
git clone --recurse-submodules https://git.jcsmith.fr/jackcartersmith/picocalc_BIOS
cd picocalc_BIOS
git checkout 1b649c8
git apply /path/to/0001-keyboard-Alt-O-reports-KEY_OVERLAY-0xE1-right-Shift-.patch
make -j
```

Needs the ARM GCC toolchain (`arm-none-eabi-gcc`). The result is in `build/`. The source files use CRLF
line endings and so does the patch; keep it unchanged (`git config core.autocrlf false` on Windows).

## Licence

picocalc_BIOS is licensed under the LGPL-3.0 (see its LICENSE file); the patch here is under the same
licence. The firmware is distributed without any warranty, see sections 15 and 16 of the GNU GPL 3.0,
which the LGPL-3.0 builds on.
