# Tested configurations

This file distinguishes development targets from verified compatibility. Do not interpret a model being listed in the UI as proof that it works on every device.

## Current prototype status

The current working hardware prototype uses a separate ESP32-CAM module that communicates with the phone over its Wi-Fi access point. The phone hosts the browser application and local model inference. The camera is not physically mounted on the glasses frame. This records maintainer-reported operation; the setup has not been independently reproduced as part of this release.

## Known development target

| Component | Known information | Evidence/status |
|---|---|---|
| Phone | Samsung Galaxy S24 FE | Original development target; record exact OS/build when re-tested |
| Browser | Chrome for Android with WebGPU | Target environment; exact tested version not recorded here |
| Inference | Transformers.js 4.3.2, WebGPU | Pinned import in `index.html`; device/model combinations need per-model test records |
| Camera | External ESP32-CAM; camera module marking: HDF3M-811-V1; additional printed marking: "ISM2 4G 802.11" | User-reported working camera-to-phone Wi-Fi prototype. The markings do not establish the ESP32 controller-board model or conclusively identify the image sensor; OV2640 remains unconfirmed. Camera is not mounted on the glasses frame. |
| Firmware compile (CI) | Arduino-ESP32 core 2.0.17; Arduino CLI 1.6.0; FQBN `esp32:esp32:esp32wrover` | CI compile passed on 2026-11-12. This verifies compilation for the Wrover target only; it does not identify or validate the user's physical ESP32-CAM board. |

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
