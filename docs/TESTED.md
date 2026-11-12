# Tested configurations

This file distinguishes development targets from verified compatibility. Do not interpret a model being listed in the UI as proof that it works on every device.

## Current prototype status

The current working hardware prototype uses a separate ESP32-CAM module that communicates with the phone over its Wi-Fi access point. The phone hosts the browser application and local model inference. The camera is not physically mounted on the glasses frame. This status records the user's description of the working setup; it is not an independent re-test of this maintenance branch.

## Known development target

| Component | Known information | Evidence/status |
|---|---|---|
| Phone | Samsung Galaxy S24 FE | Original development target; record exact OS/build when re-tested |
| Browser | Chrome for Android with WebGPU | Target environment; exact tested version not recorded here |
| Inference | Transformers.js 4.3.2, WebGPU | Pinned import in `index.html`; device/model combinations need per-model test records |
| Camera | External ESP32-CAM module | User-reported working camera-to-phone Wi-Fi prototype; exact board/sensor revision is not recorded here. Camera is not mounted on the glasses frame. |
| Firmware toolchain | Espressif Arduino-ESP32 core | Source notes 2.0.x or 3.x; exact known-good version is not yet established |

## Test record template

When validating a combination, add a row with:

- Date
- Phone model and Android version
- Browser name and exact version
- ESP32-CAM board revision and camera sensor
- Arduino-ESP32 core version and board/partition settings
- Model repository ID and selected dtype
- Model load result, inference result, latency, and any crashes
- Power source, extended-run duration, and measured temperatures

Until this matrix is populated with repeatable results, compatibility beyond the original development target should be considered unverified.
