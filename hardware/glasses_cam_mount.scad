// OpenVision – clip-on USB camera mount for ordinary eyeglasses
// ---------------------------------------------------------------
// Parametric OpenSCAD model. Measure YOUR glasses' temple arm and YOUR camera,
// edit the numbers below, press F6, then File → Export → STL.
//
// Two camera styles are supported:
//   cam_type = "board" : square UVC camera board (e.g. 32×32 mm or 38×38 mm modules
//                        with an M12 lens, or small 15–25 mm boards). The board sits
//                        in a pod with a lens hole; a snap-in back lid holds it.
//   cam_type = "tube"  : cylindrical "endoscope / borescope" head (5.5 / 7 / 8 mm).
//                        Lightest option. Held in a split collar, clamped with a zip-tie.
//   cam_type = "esp32cam" : AI-Thinker ESP32-CAM (Wi-Fi, see firmware/openvision_cam). Default
//                        mount_style = "strap": no measuring, fits almost any glasses. The board lies
//                        flat against the arm in a slim box; the OV2640 camera is bent forward on
//                        its ribbon into a tilted seat behind the lens hole; a 6×6 mm push button
//                        pokes through the side lid at the back (press toward your head).
//                        strap style: two zip-ties/O-rings round box + arm also hold the lid.
//                        clip style: two snap clips (front + rear), lid glued or taped on.
//
// The mount slides onto the temple arm right behind the hinge, on the OUTSIDE.
// It snaps on (C-shaped clip with retaining lips) and can be secured with a thin
// zip-tie through the slot. The camera points forward and slightly down (tilt).
//
// Axes: +Y = forward (where you look), +Z = up, +X = away from your head (right side).
// Set side = "left" to mirror for the left temple.
//
// Print: PETG (flexes without cracking; PLA clips snap). 0.2 mm layers, 3 walls, 30 % infill.
// The "mount" part prints with the pod's outer side on the bed (already oriented by part="mount").
// The lid prints flat, lip up. No supports needed for the clip; the lens hole bridges fine.
// esp32cam: part="mount" prints upside down (box top on the bed); the 45° fillets above the clips
// make it support-free. Cut the ESP32-CAM's header pins before fitting it (program it first).

/* [What to render] */
part = "preview";        // [preview, mount, lid, cable_clip]
side = "right";          // [right, left]
cam_type = "esp32cam";   // [board, tube, esp32cam]

/* [Camera preset – modules sold in Iran (checked 2026-11). "custom" uses the Board numbers below.] */
// ov2710_38  : Aftab Rayaneh RER-USBFHD01, OV2710 1080p UVC, 38×38 mm PCB, M12 lens
//              (pick the 2.4 mm or 3.6 mm lens). The M12 holder's square base goes through
//              the front wall; the lens then screws in from the front to set focus.
// xh57_strip : Aftab Rayaneh 1 MP XH57 "laptop-webcam" strip, 35×12×4.9 mm, 71° FOV,
//              focus 15–150 cm. Lightest board option; mounted long side vertical.
// Still MEASURE your module (calipers) and check: hole spacing, holder size, lens position.
preset = "custom";       // [custom, ov2710_38, xh57_strip]
pod_dz = 0;              // move the camera pod up (+) / down (−) relative to the arm, mm

/* [Temple arm of your glasses – measure with calipers 1–2 cm behind the hinge] */
temple_t   = 3.0;   // thickness (side to side), mm
temple_h   = 6.0;   // height (top to bottom), mm
fit_tol    = 0.25;  // clearance per side; raise to 0.35 if too tight
clip_len   = 18;    // length along the arm
clip_wall  = 1.6;
lip        = 0.9;   // retaining lip under the arm (bigger = holds tighter, harder to snap on)

/* [Board camera] */
board_w    = 32;    // PCB width  (X in the pod)
board_h    = 32;    // PCB height (Z)
board_t    = 1.6;   // PCB thickness
back_space = 7;     // room behind the PCB for connector + cable bend
lens_d     = 14;    // lens barrel / holder diameter that goes through the front
lens_hole  = "round"; // [round, square]  square = for an M12 lens holder's square base
lens_sq    = 15.5;  // side of the square hole (measure the holder base, add ~0.5)
lens_dx    = 0;     // lens offset from PCB centre
lens_dz    = 0;
hole_sp_x  = 28;    // mounting-hole spacing (0 = no holes)
hole_sp_z  = 28;
hole_d     = 2.3;   // M2 clearance
pod_wall   = 1.6;
cable_w    = 4.5;   // cable slot width in the lid

/* [Tube camera] */
tube_d     = 8.0;   // head diameter
tube_len   = 14;    // how much of the head the collar grips

/* [ESP32-CAM box (cam_type = esp32cam)] */
esp_l      = 40.5;  // board length (lies along the arm, camera end forward, antenna end back)
esp_h      = 27.0;  // board height
// Defaults come from the Ai-Thinker datasheet (27 × 40.5 × 4.5 mm ±0.2) – no calipers needed.
esp_stack  = 6.5;   // 4.5 mm board + ~1 mm cut pin stubs + 1 mm foam
cam_sq     = 9.0;   // OV2640 camera module (≈8–8.5 mm; seat is generous, the module is glued)
cam_room   = 6;     // chamber in front of the board for the camera + ribbon bend
cam_dz     = 0;     // camera height relative to the box centre
esp_lens_d = 8.0;   // lens hole (OV2640 barrel ≈ 6–7.5 mm; the module is glued behind it)
btn_sq     = 6.2;   // 6×6 mm tactile switch
btn_h      = 7.0;   // switch height incl. plunger (buy 6×6×7 mm or taller)
btn_out    = 1.0;   // how far the plunger sticks out of the lid
btn_hole   = 4.0;   // hole in the lid for the plunger
btn_z      = 2;     // button height relative to the box centre
btn_room   = 14;    // chamber behind the board: button, cable strain relief, 6.3×11 mm capacitor
rear_clip  = true;  // second clip at the back end of the box
// How the box holds onto the glasses:
//   "strap": NO measuring. Two zip-ties (or silicone bands) wrap round the box AND the temple arm,
//            guided by fins on the box's top and bottom. Fits arms ~1.5–8 mm thick, 2–15 mm tall.
//            The straps also hold the lid on. Prints flat, open side up.
//   "clip" : snap-on clips sized to temple_t / temple_h (needs the arm measured).
mount_style = "strap";  // [strap, clip]
strap_w    = 5.0;   // guide gap: fits 2.5–4.8 mm zip-ties (incl. reusable ones) or a 3 mm silicone O-ring
strap_1    = 12;    // first strap, distance from the front of the box (behind the camera)
strap_2    = 47;    // second strap (in front of the button)
fin_h      = 1.5;   // guide fin height
lid_vents  = true;  // slots over the board – put the ESP32 shield side toward the lid (away from your head)

/* [Cable clips – hold the power cable along the arm, behind the ear (part = cable_clip, print 3–4)] */
cc_t       = 3.0;   // arm thickness where the clip goes (often thicker behind the ear – measure)
cc_h       = 6.0;   // arm height there
cc_len     = 6;     // clip length along the arm
cc_cable_d = 3.5;   // cable diameter

/* [Aim] */
tilt       = 10;    // degrees the camera points down (you look slightly down when walking/reading)
toe_out    = 0;     // degrees the camera turns outward (positive = away from nose)

$fn = 48;
eps = 0.01;

// preset → effective board numbers (OpenSCAD can't reassign, so presets pick values here)
P1 = preset == "ov2710_38";
P2 = preset == "xh57_strip";
bw  = P1 ? 38  : P2 ? 12  : board_w;
bh  = P1 ? 38  : P2 ? 35  : board_h;
bt  = P1 ? 1.6 : P2 ? 4.9 : board_t;
bs  = P1 ? 7   : P2 ? 3   : back_space;   // OV2710: USB header on the back; strip: soldered cable
lh  = P1 ? "square" : lens_hole;
lsq = P1 ? 15.5 : lens_sq;                // typical M12 holder base 15 mm – measure yours
ld  = P2 ? 7 : lens_d;                    // strip: small window in front of the tiny lens
ldx = lens_dx;                            // lens offset from the board centre – applies to presets too
ldz = lens_dz;                            // (strip: measure where the lens sits on YOUR module)
hsx = (P1 || P2) ? 0 : hole_sp_x;         // presets: no screws, the lid presses the board in place
hsz = (P1 || P2) ? 0 : hole_sp_z;
// With no screw holes, the lid's lip is made deep enough to press the board against the front wall.
lip_d = (hsx > 0) ? 2.2 : max(2.2, bs - 0.3);
cam_type_eff = (P1 || P2) ? "board" : cam_type;
if (P1) echo("OV2710 board: ~15 g with M12 lens. Put the mount on the arm close to the hinge; consider a counterweight on the other arm.");
if (P2) echo("XH57 strip: check where the lens sits on YOUR module and set lens_dz / pod_dz.");

// derived
tt = temple_t + 2 * fit_tol;            // slot width
th = temple_h + 2 * fit_tol;            // slot height
clip_out_x = tt + clip_wall;            // outer face of the clip
pw = bw + 0.4 + 2 * pod_wall;           // pod outer width
ph = bh + 0.4 + 2 * pod_wall;           // pod outer height
pd = pod_wall + bt + bs;                // pod outer depth

// ---------------- temple clip ----------------
// C-profile open at the bottom, extruded along Y from -clip_len to 0.
module clip(ziptie = true) {
  difference() {
    translate([-clip_wall, -clip_len, -clip_wall])
      cube([tt + 2 * clip_wall, clip_len, th + 2 * clip_wall]);
    // slot for the arm
    translate([0, -clip_len - 1, 0]) cube([tt, clip_len + 2, th]);
    // bottom opening, leaving a lip on each side
    translate([lip, -clip_len - 1, -clip_wall - 1]) cube([tt - 2 * lip, clip_len + 2, clip_wall + 2]);
    // zip-tie slot through the top, across the arm
    if (ziptie) translate([-clip_wall - 1, -clip_len * 0.65, th + clip_wall - 0.9]) cube([tt + 2 * clip_wall + 2, 3, 2]);
  }
}

// ---------------- board pod ----------------
// Local frame: front face at y = 0, pod spans x 0..pw, centred on z = 0. Open at the back.
module board_pod() {
  translate([0, -pd, -ph / 2]) difference() {
    cube([pw, pd, ph]);
    // cavity for PCB + parts behind it
    translate([pod_wall, -eps, pod_wall]) cube([pw - 2 * pod_wall, pd - pod_wall + eps, ph - 2 * pod_wall]);
    // lens hole through the front wall (round for a barrel, square for an M12 holder base)
    translate([pw / 2 + ldx, pd - pod_wall - 1, ph / 2 + ldz])
      if (lh == "square") translate([-lsq / 2, 0, -lsq / 2]) cube([lsq, pod_wall + 2, lsq]);
      else rotate([-90, 0, 0]) cylinder(d = ld + 0.4, h = pod_wall + 2);
    // M2 holes for screws from the front (nuts behind the PCB), if the board has holes
    if (hsx > 0)
      for (sx = [-1, 1], sz = [-1, 1])
        translate([pw / 2 + sx * hsx / 2, pd - pod_wall - 1, ph / 2 + sz * hsz / 2])
          rotate([-90, 0, 0]) cylinder(d = hole_d, h = pod_wall + 2);
  }
}

// Snap-in back lid: plate + inner lip that friction-fits the cavity, with a cable slot.
module board_lid() {
  cw = pw - 2 * pod_wall - 0.3;
  ch = ph - 2 * pod_wall - 0.3;
  difference() {
    union() {
      cube([pw, ph, 1.4]);                                              // plate (prints flat)
      translate([(pw - cw) / 2, (ph - ch) / 2, 1.4]) difference() {     // lip ring
        cube([cw, ch, lip_d]);
        translate([1.2, 1.2, -eps]) cube([cw - 2.4, ch - 2.4, lip_d + 2 * eps]);
      }
    }
    // cable slot from the centre to the bottom edge, so the lid goes on over the cable
    translate([pw / 2 - cable_w / 2, -1, -1]) cube([cable_w, ph / 2 + 1, 10]);
  }
}

// ---------------- tube collar ----------------
// Split ring around the camera head, clamped with a 2.5 mm zip-tie. Local frame like the pod.
module tube_pod() {
  od = tube_d + 2 * 1.8;
  translate([od / 2, 0, 0]) difference() {
    union() {
      rotate([90, 0, 0]) cylinder(d = od, h = tube_len);
      translate([-od / 2, -tube_len, -od / 2]) cube([od / 2, tube_len, od]);   // flat side to join the clip
    }
    translate([0, 1, 0]) rotate([90, 0, 0]) cylinder(d = tube_d + 0.3, h = tube_len + 2);
    translate([-0.6, -tube_len - 1, 0]) cube([1.2, tube_len + 2, od]);         // split, top
    translate([-od, -tube_len / 2 - 1.5, -od]) difference() {                  // zip-tie groove
      cube([2 * od, 3, 2 * od]);
      translate([od, -1, od]) rotate([-90, 0, 0]) cylinder(d = od - 1.2, h = 5);
    }
  }
}

// ---------------- ESP32-CAM box ----------------
// Local frame like the pods: front face at y = 0, inner wall (against the clip) at x = 0,
// open on the outer side (+X, closed by esp_lid), centred on z = 0.
eix = max(esp_stack, cam_sq + 0.4) + 0.4;                  // inner thickness (X)
eiz = esp_h + 0.8;                                          // inner height (board ±0.2 + print tolerance)
e_front = pod_wall + (cam_sq / 2 + 0.5) * tan(tilt) + 0.3;  // front wall, thick enough for the tilted seat
eiy = cam_room + esp_l + 0.8 + btn_room;                    // inner length
ex = pod_wall + eix;
ey = e_front + eiy + pod_wall;
ez = eiz + 2 * pod_wall;
btn_y = -(ey - pod_wall - btn_room / 2);                    // button centre (local y)
main_y0 = -(ey - pod_wall);                                 // main cavity: back inner wall …
main_y1 = -(e_front + cam_room);                            // … to the camera bulkhead
esp_lip = 0.8;

// camera seat frame: origin on the inner face of the front wall, +Y = viewing direction (tilted down/out)
module cam_frame() {
  translate([pod_wall + eix / 2, -e_front, cam_dz]) rotate([0, 0, -toe_out]) rotate([-tilt, 0, 0]) children();
}

btn_seat = ex + 1.4 + btn_out - btn_h;   // x of the switch's back face (it rests on a block)

module esp_box() {
  difference() {
    translate([0, -ey, -ez / 2]) cube([ex, ey, ez]);
    // board + button chamber, open to the outside
    translate([pod_wall, main_y0, -eiz / 2]) cube([eix + 1, main_y1 - main_y0, eiz]);
    // tilted camera chamber (the module is glued against its front face), open to the outside
    cam_frame() translate([-eix / 2, -(cam_room + 3), -(cam_sq + 1) / 2]) cube([eix + 2, cam_room + 3, cam_sq + 1]);
    // lens hole
    cam_frame() translate([0, -eps, 0]) rotate([-90, 0, 0]) cylinder(d = esp_lens_d + 0.4, h = e_front + 3);
    // cable exit at the back, bottom (5V + GND to the phone / power bank). Strain relief: a small
    // zip-tie pulled tight round the cable just inside the box can't pass this 3.5 mm slot.
    translate([pod_wall + 0.5, -ey - 1, -eiz / 2]) cube([cable_w, pod_wall + 2, 3.5]);
  }
  // block the switch rests on (hangs from the top wall). Leaves an 8 mm channel at the bottom for the
  // cable + the 6.3×11 mm capacitor. 5 mm wide so the switch legs pass beside it (bend them flat).
  if (btn_seat > pod_wall)
    translate([pod_wall - eps, btn_y - 2.5, -eiz / 2 + 8]) cube([btn_seat - pod_wall + eps, 5, eiz - 8 + eps]);
  // strap guides: pairs of fins across the top and bottom faces
  if (mount_style == "strap")
    for (sy = [strap_1, strap_2], side_ = [-1, 1], zs = [-1, 1])
      translate([0, -sy + side_ * (strap_w / 2 + 0.3) - (side_ < 0 ? 1.2 : 0), zs > 0 ? ez / 2 - eps : -ez / 2 - fin_h + eps])
        cube([ex, 1.2, fin_h]);
}

// Side lid: flat plate + shallow locating rim. Prints flat. Fix with two dots of hot glue or a band of tape.
// Lid x = distance from the back of the box, lid y = distance from the TOP of the box.
module esp_lid() {
  cl = main_y1 - main_y0 - 0.3;
  ch = eiz - 0.3;
  difference() {
    union() {
      cube([ey, ez, 1.4]);
      translate([pod_wall + 0.15, pod_wall + 0.15, 1.4]) difference() {
        cube([cl, ch, esp_lip]);
        translate([1.0, 1.0, -eps]) cube([cl - 2.0, ch - 2.0, esp_lip + 2 * eps]);
      }
    }
    translate([btn_y + ey, ez / 2 - btn_z, -1]) cylinder(d = btn_hole, h = 5);   // button plunger
    // vent slots over the board (the ESP32 runs warm; keep the heat away from your temple)
    if (lid_vents)
      for (i = [0 : 3])   // 4 slots between the two straps (lid x is measured from the BACK of the box)
        translate([ey - (strap_1 + 4 + i * (strap_2 - strap_1 - 8) / 3) - 0.7, ez / 2 - 8, -1]) cube([1.4, 16, 5]);
  }
}

// ---------------- cable clip ----------------
// Snaps onto the arm like the main clip; the cable clicks into a ring on the outer side.
module cable_clip() {
  t2 = cc_t + 2 * fit_tol;
  h2 = cc_h + 2 * fit_tol;
  rc = t2 + clip_wall + cc_cable_d / 2 + 0.6;   // ring centre (x)
  difference() {
    union() {
      translate([-clip_wall, 0, -clip_wall]) cube([t2 + 2 * clip_wall, cc_len, h2 + 2 * clip_wall]);
      translate([rc, 0, h2 / 2]) rotate([-90, 0, 0]) cylinder(d = cc_cable_d + 2.4, h = cc_len);
    }
    translate([0, -1, 0]) cube([t2, cc_len + 2, h2]);                                   // arm slot
    translate([lip, -1, -clip_wall - 1]) cube([t2 - 2 * lip, cc_len + 2, clip_wall + 2]); // snap opening
    translate([rc, -1, h2 / 2]) rotate([-90, 0, 0]) cylinder(d = cc_cable_d + 0.3, h = cc_len + 2);
    translate([rc, -1, h2 / 2 - cc_cable_d * 0.35]) cube([cc_cable_d + 3, cc_len + 2, cc_cable_d * 0.7]); // cable snaps in
  }
}

module esp_mount() {
  bx = clip_out_x - 0.6;
  bz = th / 2 + pod_dz;
  clip(false);
  if (rear_clip) translate([0, -(ey - clip_len), 0]) clip(false);
  translate([bx, 0, bz]) esp_box();
  // 45° fillets on top of the clips: tie them into the box and let the part print upside down without supports
  wh = max(0, min(bx + clip_wall, bz + ez / 2 - (th + clip_wall)));
  for (y0 = rear_clip ? [0, -(ey - clip_len)] : [0])
    translate([0, y0, 0]) rotate([90, 0, 0]) linear_extrude(clip_len)
      polygon([[-clip_wall, th + clip_wall], [bx + eps, th + clip_wall], [bx + eps, th + clip_wall + wh]]);
}
esp_top = th / 2 + pod_dz + ez / 2;   // highest point when worn

// ---------------- assembly ----------------
module camera_body() { if (cam_type_eff == "board") board_pod(); else tube_pod(); }
pod_w = (cam_type_eff == "board") ? pw : tube_d + 3.6;
pod_len = cam_type_eff == "board" ? pd : tube_len;

module mount() {
  clip();
  // Pod hangs on the outer face of the clip, front-aligned, centred on the arm (+pod_dz), aimed down/out.
  translate([clip_out_x - 0.6, 0, th / 2 + pod_dz])
    rotate([0, 0, -toe_out]) rotate([-tilt, 0, 0]) camera_body();
  // gusset that ties the pod's inner side into the clip along its whole length
  hull() {
    translate([clip_out_x - 0.6, -clip_len, -clip_wall]) cube([0.6, clip_len, th + 2 * clip_wall]);
    translate([clip_out_x - 0.6, 0, th / 2 + pod_dz]) rotate([0, 0, -toe_out]) rotate([-tilt, 0, 0])
      translate([0, -min(clip_len, pod_len), -(th + 2 * clip_wall) / 2])
        cube([1.2, min(clip_len, pod_len), th + 2 * clip_wall]);
  }
}

module sided() { if (side == "left") mirror([1, 0, 0]) children(); else children(); }

if (part == "mount") {
  if (cam_type_eff == "esp32cam") {
    if (mount_style == "strap")
      // Inner face (against the arm) flat on the bed, open side up – a simple tray, no supports.
      rotate([0, -90, 0]) { if (side == "left") mirror([0, 1, 0]) esp_box(); else esp_box(); }
    else
      // Upside down: box top on the bed, clip slots open upward, fillets carry the clips. No supports.
      sided() translate([0, 0, esp_top]) rotate([0, 180, 0]) esp_mount();
  } else {
    // Outer side of the pod down on the bed (flat as long as toe_out = 0).
    sided() rotate([0, 90, 0]) translate([-(clip_out_x - 0.6 + pod_w), 0, 0]) mount();
  }
} else if (part == "cable_clip") {
  rotate([90, 0, 0]) cable_clip();   // stands on its end: profile in the layers, no overhangs
} else if (part == "lid") {
  if (cam_type_eff == "board") board_lid();
  else if (cam_type_eff == "esp32cam") {
    // the lid isn't symmetric (button hole, rim), so the left-side lid is the mirror image
    if (side == "left") translate([ey, 0, 0]) mirror([1, 0, 0]) esp_lid(); else esp_lid();
  }
  else echo("Tube camera has no lid.");
} else {
  sided() {
    if (cam_type_eff == "esp32cam") {
      bxo = mount_style == "strap" ? [0, 0, 0] : [clip_out_x - 0.6, 0, th / 2 + pod_dz];
      if (mount_style == "strap") {
        esp_box();
        // ghost temple arm against the inner face, and the two straps round box + arm
        %translate([-temple_t - 1, -80, -temple_h / 2]) cube([temple_t, 100, temple_h]);
        for (sy = [strap_1, strap_2])
          %translate([-temple_t - 1.6, -sy - strap_w / 2, -ez / 2 - 0.6]) difference() {
            cube([temple_t + 1.6 + ex + 1.4 + 0.6, strap_w, ez + 1.2]);
            translate([0.6, -1, 0.6]) cube([temple_t + 1.6 + ex + 1.4 - 0.6, strap_w + 2, ez]);
          }
      } else esp_mount();
      // ghost of the lid in place (lid x → box −y from the back, lid z → inward)
      %translate(bxo)
        multmatrix([[0, 0, -1, ex + 1.4], [1, 0, 0, -ey], [0, -1, 0, ez / 2], [0, 0, 0, 1]]) esp_lid();
    } else mount();
    // ghost of the temple arm, for checking the fit
    %translate([fit_tol, -60, fit_tol]) cube([temple_t, 80, temple_h]);
    if (cam_type_eff == "board")
      %translate([clip_out_x + pw + 8, -pd, -ph / 2 + th / 2]) rotate([90, 0, 0]) translate([0, 0, -1.4]) board_lid();
  }
}
