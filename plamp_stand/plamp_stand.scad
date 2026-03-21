$fn = 64;
view = "assembly"; // [assembly, plate]

letter_size = 6;
revision_string = "1234567";


//
// Frame where mounting holes are on the frame (not in the opening)
//

$fn = 64;

// ==========================
// PARAMETERS
// ==========================

// Inner opening (must be SMALLER than hole spacing)
inner_w = 70;   // < 75
inner_h = 120;  // < 126

// Frame thickness
frame_margin = 15;
frame_thickness = 6;
corner_radius = 6;

// Hole pattern (official portrait)
hole_d = 3.0;
hole_x = 37.5;
hole_y = 63.0;

// ==========================
// DERIVED
// ==========================

outer_w = inner_w + 2 * frame_margin;
outer_h = inner_h + 2 * frame_margin;

// ==========================
// HELPERS
// ==========================

module rounded_rect_2d(w, h, r) {
    hull() {
        for (x = [-1,1], y = [-1,1])
            translate([x*(w/2 - r), y*(h/2 - r)])
                circle(r);
    }
}

module rounded_rect(w, h, r, t) {
    linear_extrude(height = t)
        rounded_rect_2d(w, h, r);
}

// ==========================
// MODULES
// ==========================

module frame_positive() {
    rounded_rect(outer_w, outer_h, corner_radius, frame_thickness);
}

module frame_negative() {
    union() {
        // inner window
        translate([0,0,-0.1])
            rounded_rect(
                inner_w,
                inner_h,
                max(0.01, corner_radius - 2),
                frame_thickness + 0.2
            );

        // mounting holes
        for (x = [-hole_x, hole_x], y = [-hole_y, hole_y]) {
            translate([x, y, -0.1])
                cylinder(d = hole_d, h = frame_thickness + 0.2);
        }
    }
}

module frame() {
    difference() {
        frame_positive();
        frame_negative();
    }
}

// ==========================
// OUTPUT
// ==========================

frame();




module write_text(string) {
    z0 = - 0.25;
    dz= 0.5;
    translate([0, 0, z0]) {
        rotate([0,0,0]) {
            linear_extrude(dz) {
                font = "DejaVu Sans";
                text(string, size = letter_size, font = font,
                     halign = "center", valign = "center", $fn = 64);
            }
        }
    }
}
if (view == "part") {
  part();
}

if (view == "plate") {
  flat("part");
}


if (view == "assembly") {
  frame();
}

