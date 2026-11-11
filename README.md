# OpenVision

**An experimental, phone-based vision assistant controlled by a camera and button mounted on ordinary glasses.**

OpenVision captures a still image from a small glasses-mounted camera and passes it to a vision-language model running locally in the phone's browser. The model describes the scene or answers a spoken question about that frame. The phone can read the response aloud in Persian or English.

The current prototype targets Chrome for Android on a phone with WebGPU support. Model inference runs in the browser through [Transformers.js](https://github.com/huggingface/transformers.js). The intended design keeps image inference on the phone rather than sending camera frames to a cloud AI service.

> **Status:** experimental prototype. Hardware compatibility, fit, thermal behaviour, model performance, and accessibility usability have not been comprehensively validated. OpenVision is not a certified accessibility, medical, navigation, or safety device.

## How it works

1. A camera captures one still frame when requested.
2. The phone passes the image to a vision-language model running in the browser.
3. The model generates a short description or answers a question about that image.
4. Android text-to-speech can read the response aloud.

The current prototype does not perform continuous live-video analysis. The camera is opened to capture a frame and then released before inference to reduce memory pressure.

## Interaction

- **Short press:** capture a frame, describe it briefly, and read the description aloud.
- **Press and hold:** capture a frame and enter question mode for that image.
- **Physical camera button:** the ESP32-CAM firmware sends button events to the phone.

Persian is the default language; English is also available.

## Models

The browser prototype includes several model options. Availability and performance depend on the current application version and the phone's memory and WebGPU support. Model files are downloaded on first use and are not included in this repository. Check each model's upstream licence and usage conditions before use.

## Get started

1. Read the [Public Build Guide](docs/Public_Build_Guide.md) for the current hardware and phone setup.
2. Open `index.html` in the supported Android browser environment.
3. Connect and configure the camera hardware if using the ESP32-CAM build.
4. Load a model while internet access is available, then test offline operation on your device.

For a quick local test from a computer or through Termux:

```bash
python -m http.server 8080
```

Then open `http://localhost:8080` in Chrome on the same device.

## Repository layout

- `index.html` — phone-side web application and inference worker.
- `firmware/openvision_cam/` — ESP32-CAM firmware and physical-button handling.
- `hardware/` — parametric OpenSCAD parts, STL prints, and laser-cut DXF designs.
- `docs/Public_Build_Guide.md` — public-facing build and setup guide.

## Important limitations

- The current app processes still images, not continuous video.
- WebGPU support and available GPU memory vary by phone and browser.
- Larger models may fail to load or run out of memory.
- External camera compatibility varies across Android devices.
- Speech recognition and text-to-speech quality depend on installed Android services and language packs.
- AI descriptions can be wrong or incomplete. Do not rely on OpenVision for navigation, hazard detection, medical decisions, or other safety-critical tasks.

## Security

Change the default `AP_PASS` in the ESP32-CAM firmware before flashing. The password currently present in the public source is already exposed and must never be reused. The same value is used for OTA updates. Use a unique password and keep the camera network local and trusted.

## Licences

- Software and firmware: Apache License 2.0, unless a file states otherwise.
- Original hardware design files: CERN Open Hardware Licence Version 2 — Permissive (CERN-OHL-P-2.0).
- Project documentation: Creative Commons Attribution 4.0 International (CC BY 4.0).

Third-party libraries, model weights, datasets, and other external assets remain under their own terms. See the licence files for details.
