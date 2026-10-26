# Disclaimer

LyraCalc OS is a free hobby project. It is provided "as is", without warranty of any kind, express or
implied, including but not limited to the warranties of merchantability, fitness for a particular purpose
and non-infringement. To the extent permitted by applicable law, the authors are not liable for any
damage or loss caused by the use of this software, the firmware or the instructions in this repository,
including damage to hardware, batteries or data.

Use it at your own risk. In particular:

- **Keyboard firmware (STM32):** flashing firmware to the PicoCalc keyboard controller can leave the
  device unusable if it goes wrong (wrong file, interrupted flashing, power loss). The keyboard controller
  also manages the battery and power. Keep a copy of your original firmware and only flash if you know how
  to restore it.
- **Hardware mods:** soldering on the Luckfox Lyra or the PicoCalc can damage them and may void any
  warranty. Work without batteries and without a USB cable connected.
- **Batteries:** use protected 18650 cells in good condition and never leave a charging device
  unattended. Battery warnings and the automatic shutdown in LyraCalc OS are a convenience, not a safety
  feature.
- **Data:** writing an image to an SD card erases everything on it. Back up your data first.

LyraCalc OS is not affiliated with or endorsed by ClockworkPi, Luckfox, Canonical or Lexaloffle.

The licences in [LICENSE](LICENSE), [kernel/patches](kernel/patches), [firmware/stm32](firmware/stm32)
and [tic80/licenses](tic80/licenses) contain the full warranty and liability terms of each part.
