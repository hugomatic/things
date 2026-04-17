$fn = 64;
view = "assembly"; // [assembly, plate]

letter_size = 6;
revision_string = "1234567";

part_dx = 70;
part_dy = 130;
part_dz = 12;


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

//
// 4-part X-split with finger joints
//
// Pieces are generated at assembled world positions.
// For each piece there is:
//   partN()      -> final solid for piece N
//   partN_pos()  -> positive/additive geometry for piece N
//   partN_neg()  -> negative/subtractive geometry for piece N
//
// You can replace the base body in body_pos()/body_neg() later with the
// real door-sweep profile and hole logic.
//

// ---------------- parameters ----------------

dx = 240;
dy = 24;
dz = 8;

line_count = 5;     // 5 bands => 3 fingers on one side, 2 on the other
finger_len = 8;
clearance  = 0.25;

// ---------------- helpers ----------------

function left_band(i) = (i % 2 == 0);

function clamp(v, lo, hi) = max(lo, min(hi, v));

function safe_gap(clearance, pitch) = clamp(clearance, 0, pitch * 0.95);

function c1(dx) = dx / 4;
function c2(dx) = dx / 2;
function c3(dx) = 3 * dx / 4;

function pitch_y(dy, line_count) = dy / max(1, floor(line_count));

function band_y0(i, dy, line_count, owner_left, clearance) =
    let(
        pitch = pitch_y(dy, line_count),
        g = safe_gap(clearance, pitch)
    )
    i * pitch +
    ((i > 0 && ((owner_left && !left_band(i - 1)) || (!owner_left && left_band(i - 1)))) ? g / 2 : 0);

function band_y1(i, dy, line_count, owner_left, clearance) =
    let(
        pitch = pitch_y(dy, line_count),
        g = safe_gap(clearance, pitch)
    )
    (i + 1) * pitch -
    ((i < max(1, floor(line_count)) - 1 &&
      ((owner_left && !left_band(i + 1)) || (!owner_left && left_band(i + 1)))) ? g / 2 : 0);

// ---------------- primitive bands ----------------

module band_pos(x0, x1, i, dy, dz, line_count, owner_left, clearance) {
    yy0 = band_y0(i, dy, line_count, owner_left, clearance);
    yy1 = band_y1(i, dy, line_count, owner_left, clearance);
    if (x1 > x0 && yy1 > yy0)
        translate([x0, yy0, 0])
            cube([x1 - x0, yy1 - yy0, dz]);
}

// full-band negative cutter, slightly oversized in Y/Z
module band_neg(x0, x1, i, dy, dz, line_count, owner_left, clearance) {
    eps = 0.01;
    yy0 = band_y0(i, dy, line_count, owner_left, clearance);
    yy1 = band_y1(i, dy, line_count, owner_left, clearance);
    if (x1 > x0 && yy1 > yy0)
        translate([x0 - eps, yy0 - eps, -eps])
            cube([x1 - x0 + 2*eps, yy1 - yy0 + 2*eps, dz + 2*eps]);
}

// ---------------- body hooks ----------------
//
// Replace these later with your real door sweep top profile and holes.
// For now they are just the full outer box.
//
// Convention:
//   body_pos() is the outer positive shape
//   body_neg() is any global subtraction (holes, pockets, etc.)
//

module body_pos() {
    cube([dx, dy, dz]);
}

module body_neg() {
    // Example placeholder:
    // translate([20, dy/2, -1]) cylinder(h=dz+2, r=2, $fn=32);

    // empty by default
}

// ---------------- piece positive geometry ----------------
//
// These are the actual volumes owned by each piece before global trimming.
//

module part1_pos() {
    lines = max(1, floor(line_count));
    flen  = max(0, finger_len);
    x1    = c1(dx);

    union() {
        cube([x1 - flen, dy, dz]);

        for (i = [0:lines-1])
            if (left_band(i))
                band_pos(x1 - flen, x1 + flen, i, dy, dz, line_count, true, clearance);
    }
}

module part2_pos() {
    lines = max(1, floor(line_count));
    flen  = max(0, finger_len);
    x1    = c1(dx);
    x2    = c2(dx);

    union() {
        translate([x1 + flen, 0, 0])
            cube([x2 - x1 - 2*flen, dy, dz]);

        for (i = [0:lines-1]) {
            if (!left_band(i))
                band_pos(x1 - flen, x1 + flen, i, dy, dz, line_count, false, clearance);
            if ( left_band(i))
                band_pos(x2 - flen, x2 + flen, i, dy, dz, line_count, true, clearance);
        }
    }
}

module part3_pos() {
    lines = max(1, floor(line_count));
    flen  = max(0, finger_len);
    x2    = c2(dx);
    x3    = c3(dx);

    union() {
        translate([x2 + flen, 0, 0])
            cube([x3 - x2 - 2*flen, dy, dz]);

        for (i = [0:lines-1]) {
            if (!left_band(i))
                band_pos(x2 - flen, x2 + flen, i, dy, dz, line_count, false, clearance);
            if ( left_band(i))
                band_pos(x3 - flen, x3 + flen, i, dy, dz, line_count, true, clearance);
        }
    }
}

module part4_pos() {
    lines = max(1, floor(line_count));
    flen  = max(0, finger_len);
    x3    = c3(dx);

    union() {
        translate([x3 + flen, 0, 0])
            cube([dx - x3 - flen, dy, dz]);

        for (i = [0:lines-1])
            if (!left_band(i))
                band_pos(x3 - flen, x3 + flen, i, dy, dz, line_count, false, clearance);
    }
}

// ---------------- piece negative geometry ----------------
//
// These subtract away everything not belonging to the piece.
// They also include body_neg(), so holes move with the piece automatically.
//

module part1_neg() {
    union() {
        body_neg();

        // remove everything to the right of piece 1 domain
        translate([c1(dx) + finger_len, -1, -1])
            cube([dx, dy + 2, dz + 2]);
    }
}

module part2_neg() {
    union() {
        body_neg();

        // remove far left
        translate([-1, -1, -1])
            cube([c1(dx) - finger_len + 1, dy + 2, dz + 2]);

        // remove far right
        translate([c2(dx) + finger_len, -1, -1])
            cube([dx, dy + 2, dz + 2]);
    }
}

module part3_neg() {
    union() {
        body_neg();

        // remove far left
        translate([-1, -1, -1])
            cube([c2(dx) - finger_len + 1, dy + 2, dz + 2]);

        // remove far right
        translate([c3(dx) + finger_len, -1, -1])
            cube([dx, dy + 2, dz + 2]);
    }
}

module part4_neg() {
    union() {
        body_neg();

        // remove everything left of piece 4 domain
        translate([-1, -1, -1])
            cube([c3(dx) - finger_len + 1, dy + 2, dz + 2]);
    }
    %cylinder(h=12, d=5);
}

// ---------------- final pieces ----------------
//
// Final pattern:
//   difference() {
//      intersection(body_pos, partN_pos)
//      partN_neg()
//   }
//
// This makes it easy to swap in a real profile later.
//

module part1() {
    difference() {
        intersection() {
            body_pos();
            part1_pos();
        }
        part1_neg();
    }
}

module part2() {
    difference() {
        intersection() {
            body_pos();
            part2_pos();
        }
        part2_neg();
    }
}

module part3() {
    difference() {
        intersection() {
            body_pos();
            part3_pos();
        }
        part3_neg();
    }
}

module part4() {
    difference() {
        intersection() {
            body_pos();
            part4_pos();
        }
        part4_neg();
    }
}

// ---------------- demo ----------------

module assembly(explode=0) {
    // exploded preview example:
    translate([0*explode, 0, 0]) color("gold")       part1();
    translate([1*explode, 0, 0]) color("lightblue")  part2();
    translate([2*explode, 0, 0]) color("orange")     part3();
    translate([3*explode, 0, 0]) color("lightgreen") part4();
}


if (view == "part") {
  part();
}

if (view == "plate") {
  assembly(0);
}

if (view == "assembly") {
  assembly(0);
}


