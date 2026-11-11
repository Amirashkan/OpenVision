# OpenVision — Public Build Guide

OpenVision is an experimental, phone-based vision assistant. A small camera mounted to ordinary glasses captures a still image; a vision-language model running locally in the phone's browser describes the image or answers a spoken question about it. The phone can read the response aloud in Persian or English.

This guide documents the current ESP32-CAM prototype and the files in this repository. It is a hobbyist prototype, not a finished product.

## 1. System overview

The system has three parts:

1. **Glasses camera and button** — an ESP32-CAM captures a JPEG still image. A physical button sends a short-press or long-press event.
2. **Phone application** — `index.html` runs in Chrome for Android. It receives the image and button event over the camera's local Wi-Fi network.
3. **On-device AI** — a vision-language model runs in the browser through Transformers.js and WebGPU. The phone generates a description or an answer and can speak it using Android text-to-speech.

The camera does not stream continuous video in the current prototype. It captures a still frame on request. Image inference is performed on the phone; camera frames are not intentionally sent to a cloud inference service.

## 2. System diagram

![OpenVision system overview](images/system-overview.svg)

## 3. Project status and compatibility

- The current software target is Chrome for Android on a phone with working WebGPU support. The original development target was a Samsung Galaxy S24 FE; other devices may behave differently.
- The browser downloads the selected model the first time it is loaded. Later offline use depends on the model cache, browser storage, and availability of the page and its JavaScript dependencies.
- Model size and memory use vary. A model that loads on one phone may fail on another.
- The ESP32-CAM design and firmware are experimental. Verify each hardware stage on a bench before attaching it to glasses.
- This project has not been validated as an accessibility, medical, navigation, or personal-safety device.

## 4. Repository files

| Path | Purpose |
|---|---|
| `index.html` | Phone-side web application and model inference |
| `firmware/openvision_cam/openvision_cam.ino` | ESP32-CAM firmware |
| `hardware/glasses_cam_mount.scad` | Parametric glasses mount |
| `hardware/pocket_hub.scad` | Optional enclosure design |
| `hardware/openvision_esp32cam_mount.stl` | Printable mount |
| `hardware/openvision_esp32cam_lid.stl` | Printable lid |
| `hardware/laser/` | Laser-cut enclosure design files |
| `docs/` | Project documentation |

Model weights are not included in this repository. Review each model's own licence and terms before use.

## 5. Hardware approach

![ESP32-CAM wiring reference](images/esp32cam-wiring.svg)


The repository contains an ESP32-CAM implementation with a local Wi-Fi access point and a physical button. The camera is mounted to one temple of ordinary glasses; a cable connects it to the phone through USB-C OTG. The phone runs the application and the AI model.

The design files are starting points, not universal-fit parts. Check your board revision, camera module, glasses-arm dimensions, cable routing, and enclosure clearances before fabrication.

### Main components

- ESP32-CAM board compatible with the firmware (AI-Thinker-style board with OV2640 is the reference configuration).
- Small tactile push button.
- Suitable USB power cable and USB-C OTG adapter for the phone.
- Polarized electrolytic capacitor for power stability, as specified by the circuit/build notes.
- Printed or laser-cut enclosure and a secure, non-damaging attachment method.
- Glasses with enough room on one temple for the camera enclosure.

Camera modules and ESP32-CAM board variants are not interchangeable in every case. Confirm pinout, camera sensor support, ribbon orientation, and power requirements for the exact board you have.

### Electrical connections

The reference firmware uses the following button connection:

| Connection | ESP32-CAM |
|---|---|
| Button terminal A | GPIO 13 |
| Button terminal B | GND |

The camera board is powered through its 5V and GND input. The reference build notes include a capacitor across the supply rails; observe its polarity and voltage rating. Do not connect power until you have checked the board pin labels and wiring. Never rely on wire colours alone.

**Power and mounting caution:** the phone's USB port may not safely power every camera board/cable combination. Check current draw, connector temperature, voltage stability, and strain relief. Do not wear a prototype that becomes hot, has exposed conductors, or can snag on clothing.

## 6. Firmware setup

1. Install the Arduino IDE and the Espressif ESP32 board package.
2. Open `firmware/openvision_cam/openvision_cam.ino`.
3. Select the board and partition settings appropriate for your exact ESP32-CAM module. The reference configuration is documented in the source comments.
4. Before flashing, change `AP_PASS` to a unique password of at least eight characters. The value currently present in the public source is a published example and must not be reused. The same value protects the camera's OTA update interface.
5. Confirm that any optional station-mode credentials are placeholders, not real network credentials.
6. Flash the firmware using a suitable ESP32-CAM programmer.
7. Open the serial monitor and confirm that the camera starts and reports its local address.

Do not expose the camera access point or OTA service to an untrusted network. The reference design is intended for a nearby, local connection.

## 7. Fabricate and mount the enclosure

![Enclosure component layout](images/enclosure-layout.svg)

![Glasses mount cross-section](images/glasses-mount.svg)


1. Open `hardware/glasses_cam_mount.scad` in OpenSCAD.
2. Select the camera/enclosure parameters matching your hardware and measure the glasses temple.
3. Render the model and export an STL.
4. Print a test fit before making the final part. Adjust tolerances rather than forcing the board into the enclosure.
5. Keep the lens unobstructed and orient it approximately forward, with a slight downward angle if needed.
6. Secure the enclosure without crushing the glasses arm. Add strain relief to the cable and leave enough slack for normal movement and folding the glasses.
7. Check that no sharp edges, hot surfaces, loose parts, or pressure points contact the wearer.

The repository also contains a laser-cut alternative under `hardware/laser/`. Confirm material thickness and dimensions before ordering or cutting.

## 8. Set up the phone

1. Use a recent Chrome for Android version on a device with WebGPU support.
2. Serve the project from `http://localhost` on the phone or from a secure HTTPS origin. For the reference ESP32-CAM connection, the local application is served from localhost because the camera exposes a local HTTP endpoint.
3. Copy or serve `index.html` and open it in Chrome.
4. Connect the phone to the camera's Wi-Fi access point.
5. In the application settings, select the ESP32 Wi-Fi camera and confirm that the connection status is active.
6. Choose a model and load it while internet access is available. The initial download can be large.
7. Enable the preferred Persian or English Android text-to-speech voice. For spoken questions, configure speech recognition and download an offline language pack if the device supports one.

A simple local server can be started from the project directory with:

```bash
python -m http.server 8080
```

Then open `http://localhost:8080/index.html` on the same phone. On Android, a terminal environment such as Termux can run the server.

## 9. Interaction

The reference interaction is:

- **Short press:** capture a still image, describe it briefly, and read the result aloud.
- **Long press:** capture a still image and enter question mode for that image.
- **Press while listening:** finish speech input and submit the question.

The exact timing and behaviour are controlled by the application and firmware versions in the repository.

## 10. Testing and limitations

Test the system in stages:

- Verify the camera image and button events while the device is on a workbench.
- Check that the camera points where intended and that the image is upright and sufficiently clear.
- Confirm stable power and check for unexpected heating during an extended bench test.
- Test short-press and long-press behaviour repeatedly.
- Test model loading and inference before relying on offline operation.
- Test offline behaviour explicitly; cached model files do not guarantee that every page dependency will be available offline.

Known limitations include variable WebGPU support, phone memory limits, model latency, camera compatibility, speech-recognition quality, and the absence of continuous video analysis.

**Do not rely on OpenVision to cross streets, navigate hazards, identify people, read critical warnings, or make medical or safety decisions.** AI descriptions can be incomplete or incorrect. Keep ordinary situational awareness and other assistive tools in use.

## 11. Privacy

The intended design performs image inference locally on the phone. However, network behaviour also depends on the browser, the hosting origin, model download source, and any third-party libraries. Review the application and its dependencies before using it with sensitive images. The ESP32-CAM's local Wi-Fi network should use a unique password and should not be shared with untrusted users.

## 12. Licences

- Software and firmware: Apache License 2.0, unless a file states otherwise.
- Original hardware design files: CERN Open Hardware Licence Version 2 — Permissive (CERN-OHL-P-2.0).
- Project documentation: Creative Commons Attribution 4.0 International (CC BY 4.0).

Third-party libraries, model weights, datasets, and other external assets remain under their respective licences and terms. See the licence files in the repository.
