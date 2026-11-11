# OpenVision

**A phone-based, on-device vision assistant controlled by a camera and button mounted on ordinary glasses.**

OpenVision is an experimental assistive-vision project. A small camera captures a frame; a local vision-language model running in the phone's browser describes the scene or answers a spoken question about that frame. Speech output can be in Persian or English.

The current prototype targets a **Samsung Galaxy S24 FE** and Chrome for Android. Model inference runs locally through **WebGPU** using [Transformers.js](https://github.com/huggingface/transformers.js). The project is designed to avoid sending camera frames to a cloud inference service.

> **Project status:** experimental prototype. Hardware fit, camera compatibility, model performance, and accessibility usability still need real-world testing. This is not a certified medical or safety device.

## How it works

1. The camera captures one still frame when requested.
2. The phone passes that frame to a vision-language model running in the browser.
3. The model produces a short description, or answers a question about the captured frame.
4. The phone can read the response aloud using its text-to-speech engine.

There is no continuous live-video analysis in the current prototype. The camera is opened only long enough to capture a frame, then released before inference to reduce GPU-memory pressure.

## Current interaction

- **Tap:** capture a frame, describe it in 1–2 sentences, and read the description aloud.
- **Press and hold:** capture the frame at the start of the press, then open speech input to ask a question about that frame. A text field is also available.
- **Physical camera button:** the ESP32-CAM firmware sends button events to the phone. A short press describes; a long press starts question mode.

Persian is the default language; English is also available.

## Models

The browser prototype currently offers these model choices:

| Model | Approx. download size | Notes |
|---|---:|---|
| Qwen3-VL 2B | 1.4 GB | Recommended starting point |
| Qwen3.5 0.8B | 0.65 GB | Lightest option |
| Gemma 4 E2B | 3.2 GB | Larger memory requirement |
| Gemma 4 E4B | 5 GB | May run out of memory |

The first model load requires an internet connection to download model files. The browser then caches downloaded files for later use. Actual offline behavior also depends on browser caching and access to the page and its JavaScript dependencies.

## Repository layout

- `index.html` — phone-side web application and inference worker.
- `firmware/openvision_cam/` — Arduino firmware for the ESP32-CAM camera and physical button.
- `hardware/` — parametric OpenSCAD parts, STL prints, and laser-cut DXF designs.
- `docs/OpenVision_Build_Guide.pdf` — detailed build guide.
- `docs/build_guide.html` — HTML version of the build guide.
- `brief.txt` — current project brief, implementation notes, and build details.

Model files are not included in this repository.

## Phone setup

1. Use a recent version of Chrome for Android on a phone with WebGPU support.
2. Serve this repository over **HTTPS** or from **localhost**. For the ESP32 Wi-Fi camera, use localhost; the page needs to communicate with the camera's plain-HTTP local address.
3. Open `index.html`, choose a model, and load it. The first load downloads the model.
4. For spoken output, enable a Persian or English text-to-speech voice in Android settings.
5. For spoken questions, enable speech recognition and install the relevant offline language pack if available on the device.

For a quick local test from a computer or through Termux:

```bash
python -m http.server 8080
```

Then open `http://localhost:8080` in the browser on the same device. On Android, run the server in Termux and open the localhost URL in Chrome.

## Hardware

### Phase 1: wired camera

The current build uses a small USB/UVC camera mounted to a glasses temple, connected by a flexible cable to the phone through USB-C OTG. Compatibility depends on Android's support for external UVC cameras and whether Chrome exposes the camera.

### ESP32-CAM build

The repository also includes an ESP32-CAM implementation with a physical button. The camera creates a local Wi-Fi access point; the phone joins it and receives JPEG frames and button events.

The firmware supports an AI-Thinker-style ESP32-CAM with OV2640 and can fall back to software JPEG encoding for supported sensors without hardware JPEG encoding.

See the detailed guide in `docs/OpenVision_Build_Guide.pdf` for parts, wiring, firmware setup, mounting, and laser-cut alternatives.

### Firmware security note

**Change the default `AP_PASS` in the firmware before flashing or using the camera.** The same value is also used as the Arduino OTA password. Do not reuse a password that has been published in this repository.

## Known limitations

- The current app processes still images, not continuous video.
- WebGPU support and available GPU memory vary by phone and browser.
- Larger models may fail to load or run out of memory.
- External USB camera support varies across Android devices.
- Speech recognition and text-to-speech quality depend on installed Android services and language packs.
- The ESP32-CAM uses a local HTTP connection; use it only on a trusted, nearby network.

## License

Unless a file or component states otherwise, the original OpenVision source code and firmware in this repository are licensed under the **Apache License 2.0**. See [LICENSE](LICENSE).

Original hardware design files (including OpenSCAD, STL, and DXF files) are licensed under **CERN Open Hardware Licence Version 2 – Permissive (CERN-OHL-P-2.0)**. See [HARDWARE-LICENSE](HARDWARE-LICENSE).

Project documentation, including the build guide, is licensed under **Creative Commons Attribution 4.0 International (CC BY 4.0)**. See [DOCUMENTATION-LICENSE](DOCUMENTATION-LICENSE).

These licenses apply only to material you have the right to license. Third-party libraries, model weights, datasets, names, and other third-party assets remain under their own terms. In particular, the listed AI models are not relicensed by this repository; check each model's upstream license and usage conditions before downloading or redistributing it.
