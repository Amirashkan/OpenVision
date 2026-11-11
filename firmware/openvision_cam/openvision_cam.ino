// OpenVision – ESP32-CAM glasses camera + physical button (Arduino IDE)
// =======================================================================
// What it does
//   * Makes its own Wi-Fi network "OpenVision-Cam". The phone joins it; index.html (Chrome on the
//     phone) pulls JPEG frames over HTTP and listens for button presses.
//   * Button on IO13: the frame is grabbed the moment you PRESS, then the camera sends
//       "down" → "tap"  (released before 450 ms)  = describe
//       "down" → "long" (still held at 450 ms)    = ask a question (mic opens on the phone)
//     While the phone is listening, pressing again means "I'm done speaking".
//
// HTTP API (all GET, CORS open so the page can read it)
//   :80  /capture   fresh JPEG (640×480)
//   :80  /held      the JPEG grabbed at the last button press
//   :80  /status    JSON (uptime, heap, clients)
//   :80  /settings  JSON of the current image settings (resolution, quality, brightness, …)
//   :80  /control?var=NAME&val=N   change one image setting (saved in flash, kept after restart);
//                                  /control?var=reset restores the defaults below
//   :81  /events?after=N   long-poll (≤10 s): {"boot":…, "last":…, "events":[{id,type,age,frame}]}
//
// Hardware (AI-Thinker-type ESP32-CAM with OV2640 – or GC2145 / "RHYX-M21-45", detected automatically)
//   5V  ← red wire of a thin USB-A cable → phone's USB-C OTG adapter (or a power bank)
//   GND ← black wire        (white/green data wires: cut short, unused)
//   220–330 µF / 10 V capacitor (6.3×11 mm) across 5V and GND near the board (Wi-Fi current peaks over a long thin
//   cable otherwise cause brown-out resets: "Brownout detector was triggered" on Serial).
//   IO13 ── tactile button ── GND   (internal pull-up, no resistor needed)
//   Don't use IO12 for the button (boot strapping pin – the board won't start if it's held high).
//
// Arduino IDE setup
//   Boards Manager: "esp32" by Espressif (2.0.x or 3.x).
//   Board: "ESP32 Wrover Module"   PSRAM: Enabled
//   Partition scheme: "Minimal SPIFFS (1.9MB APP with OTA)"   (lets you update over Wi-Fi later)
//   First upload with the ESP32-CAM-MB USB programmer board (or a USB-serial adapter, IO0 to GND).
//   After that you can cut the header pins and update over Wi-Fi: join "OpenVision-Cam" with the
//   PC, then Tools → Port → "openvision-cam at 192.168.4.1" (password = AP_PASS).

#include <WiFi.h>
#include <ArduinoOTA.h>
#include "esp_camera.h"
#include "img_converters.h"   // software JPEG for cameras without a JPEG encoder (GC2145 / RHYX-M21)
#include "esp_http_server.h"
#include <Preferences.h>      // image settings saved in flash

// ===================== settings =====================
#define USE_AP 1                          // 1: camera makes its own Wi-Fi. 0: joins your hotspot/router.
const char* AP_SSID  = "OpenVision-Cam";
const char* AP_PASS  = "openvision123";   // 8+ characters – change it
const char* STA_SSID = "your-hotspot";    // only used when USE_AP is 0 (address is printed on Serial)
const char* STA_PASS = "your-password";

const int BUTTON_PIN = 13;                // button between IO13 and GND
const int LED_PIN    = 33;                // small red LED on the back, LOW = on
const int FLASH_PIN  = 4;                 // big white flash LED – kept off
const uint32_t DEBOUNCE_MS = 25;
const uint32_t LONG_MS     = 450;         // same as the page's on-screen button

// Image defaults. All of these can be changed from the phone page (Settings → Wi-Fi camera image
// settings); changes are saved on the camera. "Reset to defaults" there goes back to these values.
const framesize_t FRAME  = FRAMESIZE_VGA; // 640×480 – the AI uses ≤640 px anyway (also the largest size allowed)
const int         JPEG_Q = 12;            // 10 = sharper/bigger, 15 = smaller/faster (OV2640 hardware JPEG)
const int         SW_JPEG_Q = 80;         // 0–100, software JPEG quality (GC2145 / RHYX-M21 cameras)
const bool FLIP_V = false, MIRROR_H = false;  // set BOTH true if the picture is upside down
// Power/heat (the board sits next to your temple and runs from the phone's battery):
const int CPU_MHZ  = 160;                 // 240 = stock. 160 is plenty for JPEG over Wi-Fi.
const int XCLK_MHZ = 10;                  // camera clock: 20 = stock (~25 fps), 10 ≈ half the frame rate,
                                          // less heat. Only one frame per press is needed anyway.
// =====================================================

SemaphoreHandle_t camLock, heldLock;
uint8_t* heldBuf = nullptr;
size_t heldLen = 0, heldCap = 0;
uint32_t heldId = 0;
bool swJpeg = false;          // true when the camera can't make JPEG itself (GC2145 / RHYX-M21-45)
uint16_t sensorPid = 0;
int swJpegQ = SW_JPEG_Q;      // current software JPEG quality (changeable from the page)
framesize_t maxFrame = FRAME; // largest size the frame buffers were set up for (smaller for software JPEG)
bool flashOnCapture = false;  // white LED on while a picture is taken (changeable from the page)
Preferences prefs;

// One JPEG picture. Release it with releaseJpeg().
// (Declared up here, before any function: the Arduino IDE inserts function prototypes above the
//  first function, and those prototypes must already know this type.)
struct Jpeg { camera_fb_t* fb; uint8_t* buf; size_t len; bool owned; };

struct Ev { uint32_t id; uint32_t ms; const char* type; uint32_t frame; };
Ev ring[16];
volatile uint32_t lastEv = 0;
portMUX_TYPE evMux = portMUX_INITIALIZER_UNLOCKED;
uint32_t bootId = 0;
volatile uint32_t lastPollMs = 0;

// ---------------- camera ----------------
// Works with both cameras sold on ESP32-CAM boards:
//   OV2640            → the sensor makes JPEG itself (fast).
//   GC2145 / RHYX-M21 → no JPEG encoder: capture RGB565 and encode JPEG on the ESP32 (~0.2–0.4 s).
// Detected automatically: JPEG init is tried first; if the sensor refuses, RGB565 is used.
bool initCamera() {
  camera_config_t c = {};
  c.ledc_channel = LEDC_CHANNEL_0;
  c.ledc_timer   = LEDC_TIMER_0;
  c.pin_d0 = 5;  c.pin_d1 = 18; c.pin_d2 = 19; c.pin_d3 = 21;   // Y2..Y5
  c.pin_d4 = 36; c.pin_d5 = 39; c.pin_d6 = 34; c.pin_d7 = 35;   // Y6..Y9
  c.pin_xclk = 0; c.pin_pclk = 22; c.pin_vsync = 25; c.pin_href = 23;
  c.pin_sccb_sda = 26; c.pin_sccb_scl = 27;
  c.pin_pwdn = 32; c.pin_reset = -1;
  c.xclk_freq_hz = XCLK_MHZ * 1000000;
  c.pixel_format = PIXFORMAT_JPEG;
  c.frame_size   = FRAME;
  c.jpeg_quality = JPEG_Q;
  if (psramFound()) {
    c.fb_count = 2; c.fb_location = CAMERA_FB_IN_PSRAM; c.grab_mode = CAMERA_GRAB_LATEST;
  } else {
    c.fb_count = 1; c.fb_location = CAMERA_FB_IN_DRAM;  c.grab_mode = CAMERA_GRAB_WHEN_EMPTY;
  }
  esp_err_t e = esp_camera_init(&c);
  if (e != ESP_OK) {
    Serial.printf("JPEG init failed (0x%x) – trying RGB565 + software JPEG (GC2145 / RHYX-M21 camera)\n", e);
    esp_camera_deinit();
    if (!psramFound()) { c.frame_size = FRAMESIZE_QVGA; }   // a raw VGA frame (600 KB) needs PSRAM
    c.pixel_format = PIXFORMAT_RGB565;
    e = esp_camera_init(&c);
    if (e != ESP_OK) return false;
    swJpeg = true;
  }
  sensor_t* s = esp_camera_sensor_get();
  sensorPid = s->id.PID;
  s->set_vflip(s, FLIP_V);
  s->set_hmirror(s, MIRROR_H);

  if (swJpeg) {
    // Raw frames are big; if the ESP32 can't keep up at 640×480, step down until frames arrive.
    const framesize_t sizes[] = { FRAME, FRAMESIZE_HVGA, FRAMESIZE_QVGA };
    bool ok = false;
    for (framesize_t fs : sizes) {
      if (fs > FRAME) continue;
      s->set_framesize(s, fs);
      delay(400);
      for (int i = 0; i < 3 && !ok; i++) {
        camera_fb_t* fb = esp_camera_fb_get();
        if (fb) { ok = fb->len > 0; Serial.printf("raw frame %ux%u ok\n", fb->width, fb->height); esp_camera_fb_return(fb); }
      }
      if (ok) break;
    }
    if (!ok) return false;
  }
  maxFrame = s->status.framesize;
  Serial.printf("Camera sensor PID 0x%04x, %s JPEG\n", sensorPid, swJpeg ? "software" : "hardware");
  return true;
}

bool grabJpeg(Jpeg& j) {
  j = {};
  xSemaphoreTake(camLock, portMAX_DELAY);
  if (flashOnCapture) {           // light first, then skip a frame that was exposed before the light came on
    digitalWrite(FLASH_PIN, HIGH);
    delay(150);
    camera_fb_t* old = esp_camera_fb_get();
    if (old) esp_camera_fb_return(old);
  }
  camera_fb_t* fb = esp_camera_fb_get();
  if (flashOnCapture) digitalWrite(FLASH_PIN, LOW);
  if (fb && swJpeg) {
    bool ok = frame2jpg(fb, swJpegQ, &j.buf, &j.len);
    esp_camera_fb_return(fb);
    xSemaphoreGive(camLock);
    j.owned = true;
    if (!ok) { free(j.buf); j = {}; }
    return ok;
  }
  xSemaphoreGive(camLock);
  if (!fb) return false;
  j.fb = fb; j.buf = fb->buf; j.len = fb->len;
  return true;
}

void releaseJpeg(Jpeg& j) {
  if (j.owned) free(j.buf);
  else if (j.fb) esp_camera_fb_return(j.fb);
  j = {};
}

// Copy the current picture into the "held" buffer (the picture at the moment of the press).
void grabHeld() {
  Jpeg j;
  if (!grabJpeg(j)) return;
  xSemaphoreTake(heldLock, portMAX_DELAY);
  if (j.len > heldCap) {
    free(heldBuf);
    heldCap = j.len + 16384;
    heldBuf = (uint8_t*)ps_malloc(heldCap);
    if (!heldBuf) heldBuf = (uint8_t*)malloc(heldCap);
    if (!heldBuf) heldCap = 0;
  }
  if (heldBuf) { memcpy(heldBuf, j.buf, j.len); heldLen = j.len; heldId++; }
  else heldLen = 0;
  xSemaphoreGive(heldLock);
  releaseJpeg(j);
}

void pushEvent(const char* type) {
  uint32_t now = millis();
  portENTER_CRITICAL(&evMux);
  uint32_t id = lastEv + 1;
  ring[id % 16] = { id, now, type, heldId };
  lastEv = id;
  portEXIT_CRITICAL(&evMux);
  Serial.printf("button: %s\n", type);
}

// ---------------- image settings ----------------
// Changed from the phone page via /control, saved in flash ("ovcam" namespace), re-applied at boot.
// "quality" uses one 0–100 scale (higher = better) for both camera types; it's converted here.
const char* SETTING_KEYS[] = {
  "framesize", "quality", "brightness", "contrast", "saturation", "special_effect",
  "awb", "wb_mode", "aec", "aec2", "ae_level", "aec_value", "agc", "agc_gain", "gainceiling",
  "lenc", "vflip", "hmirror", "flash",
};
int hwToQ(int q) { return constrain((40 - q) * 100 / 34, 0, 100); }   // OV2640 quality: 6 (best) … 40
int qToHw(int v) { return 40 - constrain(v, 0, 100) * 34 / 100; }
int swToQ(int q) { return constrain((q - 30) * 100 / 65, 0, 100); }   // software JPEG: 30 … 95
int qToSw(int v) { return 30 + constrain(v, 0, 100) * 65 / 100; }

int defaultSetting(const char* k) {
  if (!strcmp(k, "framesize")) return maxFrame;
  if (!strcmp(k, "quality"))   return swJpeg ? swToQ(SW_JPEG_Q) : hwToQ(JPEG_Q);
  if (!strcmp(k, "awb") || !strcmp(k, "aec") || !strcmp(k, "agc") || !strcmp(k, "lenc")) return 1;
  if (!strcmp(k, "aec_value")) return 300;
  if (!strcmp(k, "vflip"))     return FLIP_V;
  if (!strcmp(k, "hmirror"))   return MIRROR_H;
  return 0;
}

// Apply one setting to the sensor. Call with camLock held. Returns false for an unknown name,
// a value out of range, or a setting this camera doesn't support.
bool applySetting(const char* k, int v) {
  sensor_t* s = esp_camera_sensor_get();
  if (!s) return false;
  int r = -1;
  // Some camera drivers leave functions they don't support empty: check before calling.
  #define CALL(fn, val) (s->fn ? s->fn(s, val) : -1)
  if      (!strcmp(k, "framesize"))      { if (v < FRAMESIZE_QQVGA || v > maxFrame) return false; r = CALL(set_framesize, (framesize_t)v); }
  else if (!strcmp(k, "quality"))        { if (swJpeg) { swJpegQ = qToSw(v); r = 0; } else r = CALL(set_quality, qToHw(v)); }
  else if (!strcmp(k, "brightness"))     r = CALL(set_brightness, constrain(v, -2, 2));
  else if (!strcmp(k, "contrast"))       r = CALL(set_contrast, constrain(v, -2, 2));
  else if (!strcmp(k, "saturation"))     r = CALL(set_saturation, constrain(v, -2, 2));
  else if (!strcmp(k, "special_effect")) r = CALL(set_special_effect, constrain(v, 0, 6));
  else if (!strcmp(k, "awb"))            r = CALL(set_whitebal, v ? 1 : 0);
  else if (!strcmp(k, "wb_mode"))        r = CALL(set_wb_mode, constrain(v, 0, 4));
  else if (!strcmp(k, "aec"))            r = CALL(set_exposure_ctrl, v ? 1 : 0);
  else if (!strcmp(k, "aec2"))           r = CALL(set_aec2, v ? 1 : 0);
  else if (!strcmp(k, "ae_level"))       r = CALL(set_ae_level, constrain(v, -2, 2));
  else if (!strcmp(k, "aec_value"))      r = CALL(set_aec_value, constrain(v, 0, 1200));
  else if (!strcmp(k, "agc"))            r = CALL(set_gain_ctrl, v ? 1 : 0);
  else if (!strcmp(k, "agc_gain"))       r = CALL(set_agc_gain, constrain(v, 0, 30));
  else if (!strcmp(k, "gainceiling"))    r = CALL(set_gainceiling, (gainceiling_t)constrain(v, 0, 6));
  else if (!strcmp(k, "lenc"))           r = CALL(set_lenc, v ? 1 : 0);
  else if (!strcmp(k, "vflip"))          r = CALL(set_vflip, v ? 1 : 0);
  else if (!strcmp(k, "hmirror"))        r = CALL(set_hmirror, v ? 1 : 0);
  else if (!strcmp(k, "flash"))          { flashOnCapture = v != 0; r = 0; }
  else return false;
  #undef CALL
  return r == 0;
}

// At boot: defaults first, then whatever was saved from the page.
void loadSettings() {
  prefs.begin("ovcam", false);
  xSemaphoreTake(camLock, portMAX_DELAY);
  for (const char* k : SETTING_KEYS) applySetting(k, prefs.getInt(k, defaultSetting(k)));
  xSemaphoreGive(camLock);
}

// Current value of a setting, on the same scale the page uses.
int currentSetting(const char* k) {
  sensor_t* s = esp_camera_sensor_get();
  const camera_status_t& st = s->status;
  if (!strcmp(k, "framesize"))      return st.framesize;
  if (!strcmp(k, "quality"))        return swJpeg ? swToQ(swJpegQ) : hwToQ(st.quality);
  if (!strcmp(k, "brightness"))     return st.brightness;
  if (!strcmp(k, "contrast"))       return st.contrast;
  if (!strcmp(k, "saturation"))     return st.saturation;
  if (!strcmp(k, "special_effect")) return st.special_effect;
  if (!strcmp(k, "awb"))            return st.awb;
  if (!strcmp(k, "wb_mode"))        return st.wb_mode;
  if (!strcmp(k, "aec"))            return st.aec;
  if (!strcmp(k, "aec2"))           return st.aec2;
  if (!strcmp(k, "ae_level"))       return st.ae_level;
  if (!strcmp(k, "aec_value"))      return st.aec_value;
  if (!strcmp(k, "agc"))            return st.agc;
  if (!strcmp(k, "agc_gain"))       return st.agc_gain;
  if (!strcmp(k, "gainceiling"))    return st.gainceiling;
  if (!strcmp(k, "lenc"))           return st.lenc;
  if (!strcmp(k, "vflip"))          return st.vflip;
  if (!strcmp(k, "hmirror"))        return st.hmirror;
  if (!strcmp(k, "flash"))          return flashOnCapture;
  return 0;
}

// ---------------- HTTP ----------------
void cors(httpd_req_t* req) {
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  httpd_resp_set_hdr(req, "Access-Control-Allow-Private-Network", "true");
  httpd_resp_set_hdr(req, "Cache-Control", "no-store");
}

esp_err_t optionsHandler(httpd_req_t* req) {   // CORS / private-network preflight
  cors(req);
  httpd_resp_set_hdr(req, "Access-Control-Allow-Methods", "GET, OPTIONS");
  httpd_resp_set_hdr(req, "Access-Control-Allow-Headers", "*");
  httpd_resp_set_status(req, "204 No Content");
  return httpd_resp_send(req, NULL, 0);
}

esp_err_t captureHandler(httpd_req_t* req) {
  Jpeg j;
  if (!grabJpeg(j)) { httpd_resp_send_err(req, HTTPD_500_INTERNAL_SERVER_ERROR, "camera"); return ESP_FAIL; }
  cors(req);
  httpd_resp_set_type(req, "image/jpeg");
  esp_err_t r = httpd_resp_send(req, (const char*)j.buf, j.len);
  releaseJpeg(j);
  return r;
}

esp_err_t heldHandler(httpd_req_t* req) {
  cors(req);
  xSemaphoreTake(heldLock, portMAX_DELAY);
  esp_err_t r;
  if (!heldLen) {
    xSemaphoreGive(heldLock);
    httpd_resp_send_err(req, HTTPD_404_NOT_FOUND, "no frame yet");
    return ESP_OK;
  }
  httpd_resp_set_type(req, "image/jpeg");
  r = httpd_resp_send(req, (const char*)heldBuf, heldLen);
  xSemaphoreGive(heldLock);
  return r;
}

esp_err_t statusHandler(httpd_req_t* req) {
  char buf[260];
  snprintf(buf, sizeof buf,
           "{\"boot\":%lu,\"uptime\":%lu,\"heap\":%lu,\"psram\":%lu,\"clients\":%d,\"held\":%lu,"
           "\"sensor\":\"0x%04x\",\"jpeg\":\"%s\"}",
           (unsigned long)bootId, (unsigned long)(millis() / 1000), (unsigned long)ESP.getFreeHeap(),
           (unsigned long)ESP.getFreePsram(), USE_AP ? WiFi.softAPgetStationNum() : 1, (unsigned long)heldId,
           sensorPid, swJpeg ? "software" : "hardware");
  cors(req);
  httpd_resp_set_type(req, "application/json");
  return httpd_resp_send(req, buf, HTTPD_RESP_USE_STRLEN);
}

// /settings → {"sensor":"0x0026","jpeg":"hardware","maxsize":10,"framesize":10,"quality":82,…}
esp_err_t settingsHandler(httpd_req_t* req) {
  String out;
  out.reserve(420);
  char head[80];
  snprintf(head, sizeof head, "{\"sensor\":\"0x%04x\",\"jpeg\":\"%s\",\"maxsize\":%d",
           sensorPid, swJpeg ? "software" : "hardware", (int)maxFrame);
  out += head;
  xSemaphoreTake(camLock, portMAX_DELAY);
  for (const char* k : SETTING_KEYS) { out += ",\""; out += k; out += "\":"; out += String(currentSetting(k)); }
  xSemaphoreGive(camLock);
  out += "}";
  cors(req);
  httpd_resp_set_type(req, "application/json");
  return httpd_resp_send(req, out.c_str(), out.length());
}

// /control?var=brightness&val=1  ·  /control?var=reset
esp_err_t controlHandler(httpd_req_t* req) {
  char q[64], var[20] = "", val[12] = "0";
  if (httpd_req_get_url_query_str(req, q, sizeof q) == ESP_OK) {
    httpd_query_key_value(q, "var", var, sizeof var);
    httpd_query_key_value(q, "val", val, sizeof val);
  }
  cors(req);
  bool ok = false;
  xSemaphoreTake(camLock, portMAX_DELAY);
  if (!strcmp(var, "reset")) {
    prefs.clear();
    for (const char* k : SETTING_KEYS) applySetting(k, defaultSetting(k));
    ok = true;
  } else {
    int v = atoi(val);
    ok = applySetting(var, v);
    if (ok) prefs.putInt(var, v);
  }
  xSemaphoreGive(camLock);
  if (!ok) { httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "unknown or unsupported setting"); return ESP_OK; }
  Serial.printf("setting %s = %s\n", var, val);
  httpd_resp_set_type(req, "application/json");
  return httpd_resp_send(req, "{\"ok\":true}", HTTPD_RESP_USE_STRLEN);
}

esp_err_t rootHandler(httpd_req_t* req) {
  static const char html[] =
    "<!doctype html><meta name=viewport content='width=device-width'>"
    "<body style='font-family:sans-serif;background:#111;color:#eee'>"
    "<p>OpenVision camera is running. Test frame:</p><img src='/capture' style='max-width:100%'>"
    "<p><a style='color:#8cf' href='/status'>status</a></p>";
  httpd_resp_set_type(req, "text/html");
  return httpd_resp_send(req, html, HTTPD_RESP_USE_STRLEN);
}

// Long-poll: waits up to 10 s for a button event newer than ?after=N.
// after=-1 (first contact) returns at once, so old presses are never replayed.
esp_err_t eventsHandler(httpd_req_t* req) {
  long after = -1;
  char q[48], v[16];
  if (httpd_req_get_url_query_str(req, q, sizeof q) == ESP_OK &&
      httpd_query_key_value(q, "after", v, sizeof v) == ESP_OK) after = atol(v);

  uint32_t start = millis();
  lastPollMs = start;
  while (after >= 0 && (long)lastEv == after && millis() - start < 10000) {
    vTaskDelay(pdMS_TO_TICKS(15));
    lastPollMs = millis();
  }

  Ev snap[16];
  uint32_t last;
  portENTER_CRITICAL(&evMux);
  memcpy(snap, ring, sizeof ring);
  last = lastEv;
  portEXIT_CRITICAL(&evMux);

  String out;
  out.reserve(400);
  out += "{\"boot\":"; out += String(bootId);
  out += ",\"last\":"; out += String(last);
  out += ",\"events\":[";
  if (after >= 0 && (uint32_t)after < last) {
    uint32_t from = (uint32_t)after + 1;
    if (last >= 16 && from < last - 15) from = last - 15;
    uint32_t now = millis();
    bool first = true;
    for (uint32_t id = from; id <= last; id++) {
      const Ev& e = snap[id % 16];
      if (e.id != id) continue;
      if (!first) out += ",";
      first = false;
      out += "{\"id\":"; out += String(e.id);
      out += ",\"type\":\""; out += e.type;
      out += "\",\"age\":"; out += String(now - e.ms);
      out += ",\"frame\":"; out += String(e.frame);
      out += "}";
    }
  }
  out += "]}";
  cors(req);
  httpd_resp_set_type(req, "application/json");
  return httpd_resp_send(req, out.c_str(), out.length());
}

void reg(httpd_handle_t s, const char* uri, httpd_method_t m, esp_err_t (*h)(httpd_req_t*)) {
  httpd_uri_t u = {};
  u.uri = uri; u.method = m; u.handler = h;
  httpd_register_uri_handler(s, &u);
}

void startServers() {
  // Port 80: frames. Port 81: button long-poll (its own task, so a waiting poll never blocks a capture).
  httpd_config_t a = HTTPD_DEFAULT_CONFIG();
  a.server_port = 80;
  a.max_uri_handlers = 8;
  a.lru_purge_enable = true;
  a.uri_match_fn = httpd_uri_match_wildcard;
  httpd_handle_t srv = NULL;
  if (httpd_start(&srv, &a) == ESP_OK) {
    reg(srv, "/", HTTP_GET, rootHandler);
    reg(srv, "/capture", HTTP_GET, captureHandler);
    reg(srv, "/held", HTTP_GET, heldHandler);
    reg(srv, "/status", HTTP_GET, statusHandler);
    reg(srv, "/settings", HTTP_GET, settingsHandler);
    reg(srv, "/control", HTTP_GET, controlHandler);
    reg(srv, "/*", HTTP_OPTIONS, optionsHandler);
  }

  httpd_config_t b = HTTPD_DEFAULT_CONFIG();
  b.server_port = 81;
  b.ctrl_port = a.ctrl_port + 1;
  b.max_open_sockets = 3;
  b.lru_purge_enable = true;
  b.uri_match_fn = httpd_uri_match_wildcard;
  httpd_handle_t ev = NULL;
  if (httpd_start(&ev, &b) == ESP_OK) {
    reg(ev, "/events", HTTP_GET, eventsHandler);
    reg(ev, "/*", HTTP_OPTIONS, optionsHandler);
  }
}

// ---------------- Wi-Fi ----------------
void startWiFi() {
  if (USE_AP) {
    WiFi.mode(WIFI_AP);
    WiFi.softAP(AP_SSID, AP_PASS, 6, 0, 2);
    Serial.printf("Wi-Fi \"%s\" – camera at http://%s\n", AP_SSID, WiFi.softAPIP().toString().c_str());
  } else {
    WiFi.mode(WIFI_STA);
    WiFi.begin(STA_SSID, STA_PASS);
    for (int i = 0; i < 40 && WiFi.status() != WL_CONNECTED; i++) delay(500);
    Serial.printf("Joined \"%s\" – camera at http://%s\n", STA_SSID, WiFi.localIP().toString().c_str());
  }
  WiFi.setTxPower(WIFI_POWER_11dBm);   // the phone is <1 m away; less power = less heat and fewer brown-outs
}

// ---------------- main ----------------
void setup() {
  Serial.begin(115200);
  setCpuFrequencyMhz(CPU_MHZ);
  pinMode(FLASH_PIN, OUTPUT); digitalWrite(FLASH_PIN, LOW);
  pinMode(LED_PIN, OUTPUT);   digitalWrite(LED_PIN, HIGH);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  camLock  = xSemaphoreCreateMutex();
  heldLock = xSemaphoreCreateMutex();
  bootId = esp_random() % 1000000000UL;

  if (!initCamera()) {
    Serial.println("Camera init failed – check the ribbon cable is fully in and latched.");
    for (int i = 0; i < 50; i++) { digitalWrite(LED_PIN, i % 2); delay(100); }
    ESP.restart();
  }
  loadSettings();
  startWiFi();
  startServers();

  ArduinoOTA.setHostname("openvision-cam");
  ArduinoOTA.setPassword(AP_PASS);
  ArduinoOTA.begin();
}

void loop() {
  ArduinoOTA.handle();

  static bool lastRaw = HIGH, stable = HIGH, longSent = false;
  static uint32_t changedAt = 0, downAt = 0;
  uint32_t now = millis();
  bool raw = digitalRead(BUTTON_PIN);
  if (raw != lastRaw) { lastRaw = raw; changedAt = now; }
  if (raw != stable && now - changedAt >= DEBOUNCE_MS) {
    stable = raw;
    if (stable == LOW) {             // pressed: grab the frame first, then tell the phone
      downAt = now; longSent = false;
      grabHeld();
      pushEvent("down");
    } else {
      pushEvent(longSent ? "up" : "tap");
    }
  }
  if (stable == LOW && !longSent && millis() - downAt >= LONG_MS) { longSent = true; pushEvent("long"); }

  // LED: steady = phone page connected, blinking = waiting for the phone
  bool online = millis() - lastPollMs < 15000;
  digitalWrite(LED_PIN, (online || (millis() / 500) % 2) ? LOW : HIGH);
  delay(5);
}
