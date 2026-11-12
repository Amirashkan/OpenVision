# Security policy

## Scope and status

OpenVision is an experimental prototype. The ESP32-CAM firmware exposes a local HTTP API and an OTA update service. The reference design is intended for a trusted, nearby device network, not an internet-facing deployment.

## Credential handling

- Copy `firmware/openvision_cam/config.example.h` to `firmware/openvision_cam/config.h`.
- Set a unique Wi-Fi access-point password of at least eight characters.
- If station mode is enabled, set its credentials locally too.
- The AP password is also used for ArduinoOTA authentication in the current firmware.
- Never commit `config.h`, real credentials, private keys, or personal network details.
- Any credential previously committed to a public repository must be considered compromised and replaced. Editing the current file does not remove it from Git history.

## Network exposure

The camera's HTTP endpoints are not authenticated. Any client able to join the camera network may be able to capture images, inspect status, or change camera settings. CORS is permissive to allow the phone page to communicate with the camera; it is not an access-control mechanism.

Do not bridge or expose the camera network, HTTP API, or OTA service to an untrusted network or the public internet. Use the camera only on a network whose clients you trust.

## Reporting

Please report suspected vulnerabilities privately to the repository maintainer rather than publishing working exploit details in an issue. Include the affected firmware/app version, impact, and reproduction steps. A response-time commitment is not currently offered.
