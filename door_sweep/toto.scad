/*
  Simple dovetail seam generator for rectangular parts.

  Idea:
  - The seam profile along X is built from 3 stacked blocks:
      positive, negative, positive
  - Call with:
      positive   = true  -> male side
      positive   = false -> female side
      right_side = true  -> seam placed on +X side
      right_side = false -> seam placed on -X side
  - gap adds clearance between the two mating parts, centered on the seam.

  Usage pattern:
    difference() {
      cube([W,D,H]);
      dovetail_cut([W,D,H], positive=false, right_side=true, ...);
    }

    union() {
      cube([W,D,H]);
      dovetail_cut([W,D,H], positive=true, right_side=false, ...);
    }

  Coordinate convention:
  - Main part is assumed to be cube([W,D,H]) at the origin.
  - Dovetail runs through full Z.
  - Joint shape varies along X, centered in Y.
*/

module dovetail_cut(
    size = [100, 20, 10],   // [W, D, H] of the base block
    positive = true,        // male or female
    right_side = true,      // seam on +X or -X side
    neck = 6,               // middle (negative) width along X
    shoulder = 10,          // top/bottom (positive) width along X
    mid_depth = 8,          // Y size of middle cube
    outer_depth = 14,       // Y size of top/bottom cubes
    gap = 0                 // clearance centered on seam
) {
    W = size[0];
    D = size[1];
    H = size[2];

    // Clamp to sane values
    _neck       = max(0.01, neck);
    _shoulder   = max(_neck, shoulder);
    _mid_depth  = min(D, max(0.01, mid_depth));
    _outer_depth= min(D, max(_mid_depth, outer_depth));
    _gap        = max(0, gap);

    y_mid   = (D - _mid_depth) / 2;
    y_outer = (D - _outer_depth) / 2;

    // Seam is centered on the side face, with optional gap opening
    // Male shrinks by gap/2, female grows by gap/2.
    male_neck     = max(0.01, _neck     - _gap);
    male_shoulder = max(male_neck, _shoulder - _gap);

    female_neck     = _neck     + _gap;
    female_shoulder = _shoulder + _gap;

    use_neck     = positive ? male_neck     : female_neck;
    use_shoulder = positive ? male_shoulder : female_shoulder;

    // X placement:
    // right side  -> joint centered at x = W
    // left side   -> joint centered at x = 0
    seam_x = right_side ? W : 0;

    module stack_shape(nx, sx) {
        union() {
            // bottom positive
            translate([-sx/2, y_outer, 0])
                cube([sx, _outer_depth, H/3]);

            // middle negative
            translate([-nx/2, y_mid, H/3])
                cube([nx, _mid_depth, H/3]);

            // top positive
            translate([-sx/2, y_outer, 2*H/3])
                cube([sx, _outer_depth, H/3]);
        }
    }

    translate([seam_x, 0, 0])
        stack_shape(use_neck, use_shoulder);
}

$fn = 32;

W = 40;
D = 20;
H = 18;
SEP = 6;

module left_part() {
    union() {
        cube([W, D, H]);
        dovetail_cut(
            size=[W,D,H],
            positive=true,
            right_side=true,
            neck=6,
            shoulder=12,
            mid_depth=8,
            outer_depth=16,
            gap=0.3
        );
    }
}

module right_part() {
    difference() {
        cube([W, D, H]);
        dovetail_cut(
            size=[W,D,H],
            positive=false,
            right_side=false,
            neck=6,
            shoulder=12,
            mid_depth=8,
            outer_depth=16,
            gap=0.3
        );
    }
}

translate([0,0,0]) left_part();
translate([W + SEP, 0, 0]) right_part();