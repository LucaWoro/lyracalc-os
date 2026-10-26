# Hardware mods

> **At your own risk.** Soldering can damage the Luckfox Lyra or the PicoCalc and may void the warranty.
> Remove the batteries and unplug USB before you start. There is no warranty and no liability for any
> damage, see [DISCLAIMER.md](../DISCLAIMER.md).

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
avoid pops.

Known problem: while booting, the speakers can crackle or hiss loudly, so turn the volume wheel down
before switching the PicoCalc on. After the PicoCalc was off for several hours, the hiss can also stay
after boot; keep the volume down or set `AUDIO=off`. A fix is planned for a later version.

## Keyboard firmware

The LyraCalc keyboard firmware makes Alt+O show and hide the status bar. Everything else works without
it. Download and flashing: [firmware/stm32](../firmware/stm32).
