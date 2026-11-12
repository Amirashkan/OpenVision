# OpenVision prototype bill of materials

This is a reference checklist for the current ESP32-CAM prototype, not a claim that every combination has been validated. Confirm exact board revision, pinout, sensor, dimensions, and power requirements before ordering.

| Item | Reference specification in this repository | Qty | Notes |
|---|---|---:|---|
| Camera board | AI-Thinker-style ESP32-CAM; OV2640 is the reference sensor | 1 | Firmware also attempts RGB565/software-JPEG fallback for some GC2145/RHYX-M21 modules; verify your exact board |
| Push button | Momentary tactile button | 1 | GPIO 13 to GND; internal pull-up |
| Capacitor | 220–330 µF, 10 V electrolytic | 1 | Across 5 V and GND near board; observe polarity |
| Power cable | USB power cable, appropriately sized conductors | 1 | Reference wiring uses 5 V and GND; data conductors are unused |
| Phone adapter | USB-C OTG adapter when powering from phone | 1 | Check phone current limits and connector temperature |
| Glasses mount | Printed mount from `hardware/glasses_cam_mount.scad` / supplied STL | 1 | Measure and test-fit the actual glasses arm |
| Optional enclosure | `hardware/pocket_hub.scad` or laser-cut files | 1 | Optional; check dimensions and material thickness |

## Electrical reference

- Button: GPIO 13 to GND.
- Supply: regulated 5 V input to the board's 5V and GND pins.
- Add the polarized capacitor near the board.
- Do not assume wire colours or board pin labels are universal; verify them with the exact hardware documentation.

## Still to be measured/documented

The repository does not currently establish a single tested vendor/SKU for all components, a measured total current draw, a verified operating temperature, or a complete cost. Add those only after measuring the actual build.
