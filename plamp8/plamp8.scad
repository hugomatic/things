$fn = 96;

view = "assembly"; // [assembly, plate]

// ---------------- dimensions ----------------
plate_w = 70;
plate_h = 120;
plate_t = 0.25;

corner_r = 6;

hole_d = 34;        // source cylinder diameter
hole_h = 24;        // final vertical height after trimming
hole_depth = 10;    // taller than plate_t for clean boolean

outlet_spacing = 42;

screw_d = 4;
screw_spacing = 84;


letter_size = 6;
write_t = 0.75;
revision_string = "1234567";



module write_text(string) {
    z0 = -0.25;
    dz= write_t;
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

module round_hull(x,y,r,h) {
    dx = x - 2 * r;
    dy = y - 2 * r;
    translate([-dx/2, -dy/2, -h/2])
    hull() {
        translate([0,0,0])cylinder(h=h, r=r);
        translate([dx,0,0]) cylinder(h=h, r=r);
        translate([dx,dy,0]) cylinder(h=h, r=r);
        translate([0,dy,0]) cylinder(h=h, r=r);
    }
}

module part_positive() {
}


module part_negative() {
}

module part() {
  difference() {
    part_positive();
    part_negative();
  }
}

module flat(part_name, x=0, y=0, angle=0) {
  if (part_name == "part") {
    rotate([180,0,0]) part();
  }
}


// ---------------- positive modules ----------------

module positive_plate_round() {
    // simple rounded-ish rectangular 3D plate
    hull() {
        for (x = [-plate_w/2 + corner_r, plate_w/2 - corner_r])
        for (y = [-plate_h/2 + corner_r, plate_h/2 - corner_r])
            translate([x, y, 0])
                cylinder(h = plate_t, r = corner_r);
    }
}

module positive_plate() {
    translate([-plate_w/2, -plate_h/2, 0])
        cube([plate_w, plate_h, plate_t]);
}

// ---------------- negative modules ----------------

module negative_roundish_outlet() {
    /*
      Start with a cylinder.
      Chop off top and bottom with cubes.
      Result: circular sides, straight-ish top/bottom,
      but controlled directly in 3D.
    */

    extra = 20;
    cut_y = hole_h / 2;

    difference() {
        // vertical cutting solid
        translate([0, 0, -hole_depth/2])
            cylinder(h = hole_depth, d = hole_d);

        // remove top cap from the cylinder
        translate([-hole_d, cut_y, -hole_depth])
            cube([2*hole_d, hole_d, 2*hole_depth]);

        // remove bottom cap from the cylinder
        translate([-hole_d, -cut_y - hole_d, -hole_depth])
            cube([2*hole_d, hole_d, 2*hole_depth]);
    }

}

module negative_screw_hole() {
    translate([0, 0, -hole_depth/2])
        cylinder(h = hole_depth, d = screw_d);
}


// ---------------- subtraction module ----------------

module subtract_cover_holes() {
    // outlet openings
    for (y = [-outlet_spacing/2, outlet_spacing/2])
        translate([0, y, plate_t/2])
            negative_roundish_outlet();

    // screw openings
    for (y = [-screw_spacing/2, screw_spacing/2])
        translate([0, y, plate_t/2])
            negative_screw_hole();

    translate([0,0, plate_t])
      rotate([0,0,0])
        write_text(revision_string);
}


// ---------------- final ----------------

module outlet_cover() {
    difference() {
        positive_plate();
        subtract_cover_holes();
    }
}



if (view == "part") {
  part();
}

if (view == "plate") {
  flat("part");
}

if (view == "assembly") {
  translate([200,0,0])part();
  outlet_cover();
}

