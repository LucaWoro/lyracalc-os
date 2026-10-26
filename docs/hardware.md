# Hardware mods

## Sound

**Needed for any sound.** On a stock PicoCalc with a Luckfox Lyra the speaker amplifier is wired to a Lyra
pin that cannot output audio. The LyraCalc OS sound driver outputs PWM audio (8 kHz, 8 bit, 64 kHz
carrier) on Lyra pin **RMIO12** (GPIO0_B4, PWM0 channel 0). The mod routes this signal to the amplifier:

1. On the Lyra, remove the 0 Ω resistor that connects the amplifier line to its original pin, so that pin
   no longer drives the line.
2. Solder a thin wire bridge from RMIO12 to the amplifier line.

A step-by-step guide with photos follows.

After the mod, sound works in PICO-8, TIC-80 and everything that uses ALSA (`aplay`, `speaker-test`).
The volume is set with the PicoCalc volume wheel. `audiooff` and `audioon` mute and unmute,
`AUDIO=off` in the settings keeps the driver from loading.

The device tree keeps the pin pulled low from early boot and the driver fades the output in and out to
avoid pops. Known problem: after the PicoCalc was off for several hours, the speakers can hiss after boot and keep
hissing; turn the volume down or set `AUDIO=off` until this is fixed.

## Keyboard firmware

The LyraCalc keyboard firmware makes Alt+O show and hide the status bar. Everything else works without
it. Download and flashing: [firmware/stm32](../firmware/stm32).
