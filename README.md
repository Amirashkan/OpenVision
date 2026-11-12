# OpenVision

**An experimental phone-based vision assistant using an external ESP32-CAM and a phone.**

In the current working hardware prototype, a separate ESP32-CAM captures a still image and sends it to the phone over its Wi-Fi access point. A vision-language model runs locally in the phone's browser. The camera is not yet mounted on the glasses frame; wearable mounting is a future integration step. The model describes the scene or answers a spoken question about that frame. The phone can read the response aloud in Persian or English.

The current prototype targets Chrome for Android on a phone with WebGPU support. Model inference runs in the browser through [Transformers.js](https://github.com/huggingface/transformers.js). Image inference is intended to remain on-device; this does **not** mean the complete application is self-contained or permanently offline.

> **Status:** experimental prototype. Hardware compatibility, fit, thermal behaviour, model performance, and accessibility usability have not been comprehensively validated. OpenVision is not a certified accessibility, medical, navigation, or safety device.

## How it works

1. The external ESP32-CAM captures one still frame when requested and makes it available to the phone over local Wi-Fi.
2. The phone passes the image to a vision-language model running in the browser.
3. The model generates a short description or answers a question about that image.
4. Android text-to-speech can read the response aloud.

The current prototype does not perform continuous live-video analysis. The camera is opened to capture a frame and then released before inference to reduce memory pressure.

## Interaction

- **Short press:** capture a frame, describe it briefly, and read the description aloud.
- **Press and hold:** capture a frame and enter question mode for that image.
- **Physical camera button:** the ESP32-CAM firmware sends button events to the phone.

Persian is the default language; English is also available.

## Models and network requirements

The app imports Transformers.js 4.3.2 from jsDelivr and downloads model files from the model repositories configured in `index.html` (currently Hugging Face). Model weights are not included in this repository. First use therefore requires network access. Later use may benefit from browser/model caches, but offline availability of the page, runtime, model files, speech services, and browser APIs is not guaranteed.

Check each model's upstream licence and usage conditions before use. Model availability and performance depend on the phone's memory and WebGPU support.

## Get started

1. Read the [Public Build Guide](docs/Public_Build_Guide.md).
2. Serve the project over HTTP or HTTPS; do not open `index.html` as a `file://` URL.
3. For a local test on the same device, run:

   ```bash
   python -m http.server 8080
   ```

   Then open `http://localhost:8080/` in Chrome on that device. If the server runs on another computer, use that computer's reachable LAN address instead of `localhost`; browser security restrictions may differ.
4. Configure and connect the external ESP32-CAM to the phone over its Wi-Fi access point.
5. Load a model while internet access is available, then explicitly test the desired offline scenario.

## Firmware credentials

Before compiling firmware, copy `firmware/openvision_cam/config.example.h` to `firmware/openvision_cam/config.h` and replace the example values with unique local credentials. `config.h` is ignored by Git. The AP password is also used for ArduinoOTA authentication. Never reuse credentials that have appeared in public Git history; changing the current source does not erase historical commits.

See [SECURITY.md](SECURITY.md) before connecting the camera to a network.

## Repository layout

- `index.html` — phone-side web application and inference worker.
- `firmware/openvision_cam/` — ESP32-CAM firmware and local configuration template.
- `hardware/` — parametric OpenSCAD parts, STL prints, and laser-cut DXF designs for future physical integration; these files do not indicate that the camera is already mounted on glasses.
- `docs/Public_Build_Guide.md` — public-facing build and setup guide.
- `docs/BOM.md` — reference bill of materials and unresolved measurements.
- `docs/TESTED.md` — compatibility status and test-record template.

## Limitations and safety

- The app processes still images, not continuous video.
- WebGPU support and available GPU memory vary by phone and browser.
- Larger models may fail to load or run out of memory.
- External camera compatibility varies across Android devices.
- Speech recognition and text-to-speech quality depend on installed Android services and language packs.
- AI descriptions can be wrong or incomplete. Do not rely on OpenVision for navigation, hazard detection, identifying people, medical decisions, reading critical warnings, or other safety-critical tasks. Maintain ordinary situational awareness and other assistive tools.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Please do not submit credentials, personal images, model weights, or generated production media.

## Licences

- Software and firmware: Apache License 2.0 ([LICENSE](LICENSE)).
- Original hardware design files: CERN-OHL-P-2.0 ([HARDWARE-LICENSE](HARDWARE-LICENSE)).
- Original project documentation: CC BY 4.0 ([DOCUMENTATION-LICENSE](DOCUMENTATION-LICENSE)).

These notices describe project-authored material only. Third-party libraries, model weights, datasets, fonts, and other external assets remain under their own terms. See the relevant upstream project before redistribution.
