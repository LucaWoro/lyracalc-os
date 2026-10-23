# PicoCalc keyboard firmware patch

A small patch for the STM32 keyboard firmware
[picocalc_BIOS](https://git.jcsmith.fr/jackcartersmith/picocalc_BIOS) (tested on commit `1b649c8`):

- Alt+O sends the key code `0xE1`, which the LyraCalc OS keyboard driver reports as `KEY_PROG1`
  (show and hide the status bar)
- right Shift is reported as left Shift

Only the patch is published here. Get the firmware source from its repository and follow its README
for building and flashing:

```sh
git clone https://git.jcsmith.fr/jackcartersmith/picocalc_BIOS
cd picocalc_BIOS
git checkout 1b649c8
git apply /path/to/0001-keyboard-Alt-O-reports-KEY_OVERLAY-0xE1-right-Shift-.patch
make
```

The source files use CRLF line endings; the patch does too, so keep it unchanged
(`git config core.autocrlf false` on Windows).

LyraCalc OS works without this patch; only Alt+O is missing (use the `overlay` command instead).
