// OpenVision – ESP32-CAM glasses box, LASER-CUT ACRYLIC (plexiglass) version
// ---------------------------------------------------------------------------
// Same job as glasses_cam_mount.scad (cam_type "esp32cam", mount_style "strap"), redesigned as a
// stack of flat layers so a laser-cutting shop can make it from one sheet of acrylic.
//
//   layer 0          BASE   – solid plate against the temple arm (stick the anti-slip pad here)
//   layer 1          FRAME  – board cavity + hexagonal nut traps (M2 nuts drop in, can't turn)
//   layers 2 … n     FRAME  – board cavity, camera pocket, lens window, cable exit
//   last layer       LID    – screw holes, button hole, vent slots (away from your head)
//
// The lower frame layers keep a small "island" in the button chamber: the 6×6 mm switch rests on it
// and its plunger pokes ~1 mm through the lid. The camera pocket and lens window are cut at the tilt
// angle INSIDE the layers, so the 10° down-tilt comes for free – no angled parts.
// 4 × M2 screws from the lid side into the nuts hold everything together (lid stays removable).
// Optional: bond base + frames with acrylic cement (chloroform / "چسب پلکسی") for a stiffer box.
// Two zip-ties / O-rings in the notches strap the box to the arm, exactly like the printed version.
// The same parts fit the LEFT or RIGHT temple – just turn the assembled box around.
// The small chamfer on one corner of every layer marks top-front: stack all chamfers together.
//
// USE: set sheet_t to your acrylic's REAL thickness (measure it – "2 mm" is often 1.8–2.2),
//      set kerf to the shop's laser kerf, then
//      part = "sheet"  → F6 → File → Export → DXF or SVG  (all layers laid out, ready to cut)
//      part = "preview" for the 3D stack, part = "layer" + layer = i for one part.
// Axes in the layers: horizontal = along the arm (front of the box at the RIGHT edge, x = 0),
// vertical = up. Stack axis = away from your head.

/* [What to render] */
part    = "preview";   // [preview, sheet, layer]
layer   = 0;           // layer index for part = "layer" (0 = base)
explode = 0;           // preview: spread the layers apart, mm

/* [Acrylic sheet + laser] */
sheet_t = 2.0;    // acrylic thickness, mm (2 or 3 mm are common; measure yours)
kerf    = 0.15;   // laser kerf (cut width); paths are offset by kerf/2 so parts come out true to size.
                  // Set 0 if the shop compensates kerf itself (ask them).
copies  = 1;      // sets on the cutting sheet (2 = a spare set, acrylic is cheap)
gap     = 3;      // spacing between parts on the cutting sheet
wall    = 2.5;    // side walls of the frame layers (acrylic is brittle: keep ≥ 2.2)
corner_r = 1.5;   // rounded corners
chamfer  = 3.0;   // top-front corner chamfer (orientation mark)

/* [ESP32-CAM – Ai-Thinker datasheet, no calipers needed] */
esp_l      = 40.5;  // board length (camera end forward, antenna end back)
esp_h      = 27.0;  // board height
esp_stack  = 6.5;   // 4.5 mm board + ~1 mm cut pin stubs + 1 mm foam
cam_sq     = 9.0;   // OV2640 camera module seat (module ≈ 8–8.5 mm, glued)
cam_room   = 6;     // solid zone in front of the board: camera pocket + ribbon bend
cam_dz     = 0;     // camera height relative to the box centre
esp_lens_d = 8.0;   // lens window (OV2640 barrel ≈ 6–7.5 mm)
tilt       = 10;    // degrees the camera points down

/* [Button – 6×6 mm tactile switch] */
btn_sq   = 6.2;
btn_h    = 7.0;     // switch height incl. plunger (6×6×7 mm; 6×6×8 also fine)
btn_out  = 1.0;     // wanted plunger height above the lid (actual value is echoed)
btn_hole = 4.2;     // lid hole for the plunger
btn_z    = 2;       // button height relative to the box centre
btn_room = 14;      // chamber behind the board: button, 6.3×11 mm capacitor, cable

/* [Screws, cable, straps] */
screw_d  = 2.4;     // M2 clearance hole
nut_af   = 4.05;    // M2 nut across flats + 0.05 (finished size – kerf is compensated below)
nut_t    = 1.6;     // M2 nut thickness
room_z   = 9.5;     // half-height of the button chamber (the steps above/below stop the board)
cable_d  = 4.0;     // cable exit (3.5 mm cable). A zip-tie round the cable inside can't pull out.
cable_z  = -6;      // cable exit height relative to the box centre
strap_w  = 5.0;     // strap notch width: 2.5–4.8 mm zip-ties or a 3 mm silicone O-ring
strap_1  = 12;      // first strap, from the front of the box
strap_2  = 47;      // second strap
notch_d  = 0.8;     // notch depth in the top and bottom edges
lid_vents = true;   // vent slots in the lid over the board

$fn = 48;
eps = 0.01;

// ---------------- derived ----------------
t       = sheet_t;
cav_need = max(esp_stack, cam_sq + 0.4) + 0.4;
nf      = ceil(cav_need / t);                // number of frame layers
N       = nf + 2;                            // base + frames + lid
T       = N * t;                             // total stack thickness
xc      = t + nf * t / 2;                    // camera / cable centre in the stack

eiz     = esp_h + 0.8;                       // board cavity height
ez      = eiz + 2 * wall;                    // box height
e_front = wall + (cam_sq / 2 + 0.5) * tan(tilt) + 0.3;
ey      = e_front + cam_room + esp_l + 0.8 + btn_room + wall;   // box length
main_y1 = -(e_front + cam_room);             // front end of the board cavity
board_y0 = main_y1 - (esp_l + 0.8);          // back end of the board = front of the button chamber
main_y0 = -(ey - wall);                      // back inner wall
btn_y   = (main_y0 + board_y0) / 2;

nut_r   = nut_af / sqrt(3);                  // hex: centre → corner
scr_z   = room_z + nut_af / 2 + 1.0;      // hex flats face up/down
screws  = [ for (sz = [-1, 1]) [main_y1 / 2, sz * scr_z],          // front pair, beside the camera pocket
            for (sz = [-1, 1]) [main_y0 + 1.5, sz * scr_z] ];      // back pair, corners of the button chamber

n_isl   = max(0, min(nf, round((T + btn_out - btn_h - t) / t)));   // frame layers with the button island
btn_top = t + n_isl * t + btn_h - T;                                  // plunger height above the lid

scr_min = T - 2 * t + nut_t;                 // screw must reach through the nut …
scr_len = [ for (L = [6, 8, 10, 12, 14, 16, 18, 20, 25]) if (L >= scr_min - 0.3 && L <= T) L ];

echo(str("Layers: ", N, " × ", t, " mm acrylic (1 base, ", nf, " frame, 1 lid). Box ",
         round(ey * 10) / 10, " × ", round(ez * 10) / 10, " × ", T, " mm."));
echo(str("Screws: 4 × M2 × ", len(scr_len) ? scr_len[0] : "?", " mm (pan head) + 4 M2 nuts. Any length ",
         scr_min, "–", T, " mm works."));
echo(str("Button: plunger sticks out ", btn_top, " mm (switch rests on frame layers 1–", n_isl, ")."));
if (btn_top < 0.3) echo("WARNING: button too short – use a taller switch (6×6×8 / 9.5 mm) or raise btn_out.");
if (btn_top > 2.5) echo("WARNING: button sticks out a lot – use a shorter switch or lower btn_out.");
if (wall < 2.2) echo("WARNING: walls under 2.2 mm crack easily in acrylic.");

// ---------------- 2D helpers ----------------
// Height of the slice of a circle (radius r, centre c on the stack axis) inside a layer [x0, x1].
// Gives a stepped round hole through the stack: lens window and cable exit.
function chord(r, x0, x1, c) =
  let (d = (c >= x0 && c <= x1) ? 0 : min(abs(x0 - c), abs(x1 - c)))
  d >= r ? 0 : 2 * sqrt(r * r - d * d);

module cam2d() { translate([-e_front, cam_dz]) rotate(-tilt) children(); }   // camera frame, tilted down

module hex(af) { circle(r = af / sqrt(3), $fn = 6); }

module outline() {
  difference() {
    offset(r = corner_r) offset(delta = -corner_r)
      polygon([[-ey, -ez / 2], [0, -ez / 2], [0, ez / 2 - chamfer], [-chamfer, ez / 2], [-ey, ez / 2]]);
    for (sy = [strap_1, strap_2], zs = [-1, 1])
      translate([-sy - strap_w / 2, zs > 0 ? ez / 2 - notch_d : -ez / 2 - 1]) square([strap_w, notch_d + 1]);
  }
}

// Everything that is cut out of frame layer k (1 … nf), which spans x0 … x1 in the stack.
module frame_holes(k, x0, x1) {
  // board cavity
  translate([board_y0, -eiz / 2]) square([main_y1 - board_y0, eiz]);
  // button chamber (lower frame layers keep an island under the switch, hanging from the top step)
  difference() {
    translate([main_y0, -room_z]) square([board_y0 - main_y0 + eps, 2 * room_z]);
    if (k <= n_isl)
      translate([btn_y - 2.5, btn_z - btn_sq / 2 - 1]) square([5, room_z - (btn_z - btn_sq / 2 - 1) + 1]);
  }
  // tilted camera pocket (module glued against its front face) – overlaps the board cavity for the ribbon
  cam2d() translate([-(cam_room + 3), -(cam_sq + 1) / 2]) square([cam_room + 3, cam_sq + 1]);
  // lens window through the front wall
  hl = chord((esp_lens_d + 0.4) / 2, x0, x1, xc);
  if (hl > 0) cam2d() translate([-1, -hl / 2]) square([e_front + 6, hl]);
  // cable exit through the back wall
  hc = chord(cable_d / 2, x0, x1, xc);
  if (hc > 0) translate([-ey - 1, cable_z - hc / 2]) square([wall + 1 + eps + 1, hc]);
  // screws: nut traps in frame 1, plain holes above
  for (s = screws) translate(s) if (k == 1) hex(nut_af); else circle(d = screw_d);
}

module lid_holes() {
  for (s = screws) translate(s) circle(d = screw_d);
  translate([btn_y, btn_z]) circle(d = btn_hole);
  if (lid_vents)
    for (i = [0 : 3])
      translate([-(strap_1 + 4 + i * (strap_2 - strap_1 - 8) / 3) - 0.7, -8]) square([1.4, 16]);
}

// One finished layer, kerf-compensated. i = 0 (base) … N-1 (lid).
module layer2d(i) {
  offset(delta = kerf / 2) difference() {
    outline();
    if (i == 0)          for (s = screws) translate(s) circle(d = screw_d);   // room for over-long screws
    else if (i == N - 1) lid_holes();
    else                 frame_holes(i, i * t, (i + 1) * t);
  }
}

function layer_name(i) = i == 0 ? "base" : i == N - 1 ? "lid" : str("frame ", i);

// ---------------- output ----------------
if (part == "layer") {
  layer2d(layer);
} else if (part == "sheet") {
  // two columns, front edges to the right; parts in stacking order (left→right, top→bottom)
  cols = 2;
  for (c = [0 : copies - 1], i = [0 : N - 1]) {
    n = c * N + i;
    translate([(n % cols) * (ey + gap) + ey, -floor(n / cols) * (ez + gap)]) layer2d(i);
  }
} else {
  // 3D preview: stack axis = +X (away from the head), +Y = forward, +Z = up
  for (i = [0 : N - 1])
    color(i == 0 || i == N - 1 ? [0.75, 0.9, 1, 0.55] : [0.55, 0.75, 0.95, 0.75])
      multmatrix([[0, 0, 1, i * (t + explode)], [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]])
        linear_extrude(t) layer2d(i);
  // ghosts: temple arm, board, camera module, switch
  %translate([-4, -90, -3]) cube([3, 110, 6]);
  %translate([t, board_y0 + 0.4, -esp_h / 2]) cube([esp_stack, esp_l, esp_h]);
  %translate([xc - 4.25, -e_front - 3, cam_dz - 4.25]) cube([8.5, 3, 8.5]);
  %translate([t + n_isl * t, btn_y - btn_sq / 2, btn_z - btn_sq / 2]) cube([btn_h, btn_sq, btn_sq]);
}
