# Hardware mods

LyraCalc OS runs on a stock PicoCalc with a Luckfox Lyra. Two optional changes add features.

## Sound

The PicoCalc speaker amplifier is not connected to the Lyra. The LyraCalc OS sound driver outputs PWM
audio (8 kHz, 8 bit) on Lyra pin **RMIO12** (GPIO0_B4, PWM0 channel 0). With a wire from this pin to the
input of the PicoCalc speaker amplifier, sound works in PICO-8, TIC-80 and everything that uses ALSA.

The volume is set with the PicoCalc volume wheel. The device tree keeps the pin pulled low until the
driver takes over, and the driver fades the output in and out, so there is no crackle at power-on and
no noise while nothing plays.

Without the mod, set `AUDIO=off` (setup wizard or `picocalc-config`).

## Keyboard firmware

The patch in [firmware/stm32](../firmware/stm32) makes the keyboard send a code for Alt+O, which
shows and hides the status bar. Everything else works without it.
