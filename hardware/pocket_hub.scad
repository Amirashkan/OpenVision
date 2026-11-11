// OpenVision – pocket hub: battery + charger + 5 V boost + backup button, for the ESP32-CAM glasses
// -------------------------------------------------------------------------------------------------
// The glasses talk to the phone over Wi-Fi, so the hub only POWERS the camera (and carries a second
// button). One 4-core cable (an ordinary USB cable, cut) runs from the hub to the glasses:
//     red   = 5V   → ESP32-CAM 5V      black = GND → ESP32-CAM GND
//     green = BTN  → ESP32-CAM IO13    (hub button = same as the glasses button, wired in parallel)
//     white = unused
// Don't plug this glasses cable into a phone or PC: its D+ wire is now the button line.
//
// Electronics (pick one):
//   A) "power-bank" module with IP5306 (or similar): charge + protection + 5 V boost + USB-A out
//      + charge LEDs on ONE board. Simplest. Keeps running as long as the load is > ~50 mA (the
//      ESP32-CAM draws 150–300 mA, so it won't auto-switch off).
//   B) TP4056 Type-C charger WITH protection (DW01) + MT3608 boost set to 5.1 V, output soldered
//      to the cable. Uses both bays below.
// Battery: 1S LiPo pouch, 1000 mAh ≈ 3–5 h, 2000 mAh ≈ 6–10 h. Buy one with a protection board.
// Also: SS12D00 slide switch (in the battery + line), 6×6 or 12×12 tactile button, 470 µF cap
// across the 5 V output.
//
// Layout (inner, mm): battery flat on the floor; modules on top of it, charger at the -X end with
// its Type-C facing out, boost/output at the +X end. Measure YOUR parts and edit the numbers.
// Print: PETG, box open side up, lid flat (rim up). No supports.

/* [What to render] */
part = "preview";      // [preview, box, lid]

/* [Parts – measure yours] */
bat_l = 50;   bat_w = 34;   bat_t = 6;     // LiPo pouch (503450 = 1000 mAh; 604060 ≈ 2000 mAh)
chg_l = 28;   chg_w = 17.5; chg_t = 5;     // TP4056 Type-C board (or the power-bank module)
out_l = 37;   out_w = 17.5; out_t = 7;     // MT3608 board (option B) – set out_l = 0 for option A
usbc_w = 9.6; usbc_h = 3.8; usbc_z = 1.2;  // Type-C opening, z = above the module's PCB bottom
wall = 1.8;
gap  = 1.0;                                 // spare room around parts

/* [Openings] */
out_type = "cable";   // [cable, usb_a]   cable = gland hole for the glasses cable; usb_a = socket opening
cable_d  = 4.2;       // glasses cable diameter + 0.3
usba_w = 13.6; usba_h = 6.0;
sw_w = 9.0;  sw_h = 4.6;                    // slide-switch lever slot (SS12D00), on the long side
btn_d = 7.5;                                // hole in the lid for the button cap (12×12 switch: 7.5)
led_d = 2.2;  led_x = 8;                    // light hole above the charger LEDs (from the -X end)

/* [Pocket clip] */
clip = true;
clip_len = 40; clip_t = 1.8; clip_gap = 1.6; clip_w = 14;

$fn = 40;
eps = 0.01;

il = max(bat_l, chg_l + out_l + 2) + 2 * gap;     // inner length (X)
iw = max(bat_w, chg_w, out_w) + 2 * gap;           // inner width  (Y)
ih = bat_t + max(chg_t, out_t) + 1.5 + gap;       // inner height (Z): battery + modules + wires
L = il + 2 * wall; W = iw + 2 * wall; H = ih + wall;   // box (open top, lid adds 1.6)
mod_z = wall + bat_t + 1.0;                        // module PCBs sit on the battery on 1 mm foam tape
echo(str("Hub outside: ", L, " × ", W, " × ", H + 1.6, " mm"));

module box() {
  difference() {
    cube([L, W, H]);
    translate([wall, wall, wall]) cube([il, iw, ih + 1]);
    // Type-C charge port, -X end, centred on the charger
    translate([-1, wall + gap + chg_w / 2 - usbc_w / 2, mod_z + usbc_z]) cube([wall + 2, usbc_w, usbc_h]);
    // output, +X end
    if (out_type == "cable")
      translate([L - wall - 1, W / 2, mod_z + 3]) rotate([0, 90, 0]) cylinder(d = cable_d, h = wall + 2);
    else
      translate([L - wall - 1, W / 2 - usba_w / 2, mod_z + 1.5]) cube([wall + 2, usba_w, usba_h]);
    // slide switch, long side
    translate([L / 2 - sw_w / 2, -1, mod_z + 1]) cube([sw_w, wall + 2, sw_h]);
  }
  // cable strain relief: a bar inside the +X end to tie the cable to with a zip-tie
  if (out_type == "cable") translate([L - wall - 8, W / 2 + cable_d, wall]) cube([2, 2, mod_z - wall + 2]);
  // pocket clip on the -Y side: joined at the top, free at the bottom (slides over a pocket edge)
  if (clip) translate([L / 2 - clip_w / 2, 0, 0]) {
    translate([0, -clip_gap - clip_t, H - 4]) cube([clip_w, clip_gap + clip_t + eps, 4]);   // bridge
    translate([0, -clip_gap - clip_t, H - clip_len]) cube([clip_w, clip_t, clip_len]);        // tongue
    translate([0, -clip_gap - clip_t - 0.8, H - clip_len]) cube([clip_w, 0.8 + eps, 2]);       // grip bump
  }
}

module lid() {
  difference() {
    union() {
      cube([L, W, 1.6]);
      translate([wall + 0.15, wall + 0.15, 1.6]) difference() {         // locating rim (snap/friction fit)
        cube([il - 0.3, iw - 0.3, 2]);
        translate([1.2, 1.2, -eps]) cube([il - 2.7, iw - 2.7, 2 + 2 * eps]);
      }
    }
    translate([L / 2, W / 2, -1]) cylinder(d = btn_d, h = 5);           // button cap
    translate([wall + led_x, wall + gap + chg_w / 2, -1]) cylinder(d = led_d, h = 5);   // charge LEDs
  }
}

if (part == "box") box();
else if (part == "lid") lid();
else {
  box();
  %translate([0, W, H + 1.6]) rotate([180, 0, 0]) lid();
  // ghosts of the parts, to check the fit
  %translate([wall + gap, wall + gap, wall]) cube([bat_l, bat_w, bat_t]);
  %translate([wall + gap, wall + gap, mod_z]) cube([chg_l, chg_w, chg_t]);
  if (out_l > 0) %translate([L - wall - gap - out_l, wall + gap, mod_z]) cube([out_l, out_w, out_t]);
}
