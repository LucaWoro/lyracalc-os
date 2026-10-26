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

From the picocalc_BIOS README:

1. Switch the PicoCalc off and take out the batteries.
2. Open the case and set pin 1 of the DIP switch **SW701** to ON.
3. Connect the PicoCalc USB-C port to the computer and press the power button.
4. Open [STM32CubeProgrammer](https://www.st.com/en/development-tools/stm32cubeprog.html), choose **UART**,
   select the port and connect.
5. Flash the `.bin` file.
6. Set pin 1 of SW701 back to OFF.
7. Take out the batteries once more, put them back and switch the PicoCalc on.

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
licence.
