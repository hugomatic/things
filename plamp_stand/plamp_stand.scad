view = "assembly"; // [assembly, tripod, camera_plate]

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
frame_thickness = 6; // 6;
screw_thickness = 2; // 3;
corner_radius = 6;

// Hole pattern (official portrait)
hole_d = 3.5;
hole_x = 35.355; // 37.5;
hole_y = 70; // 63.0;

// position of the tripod mount
elevator_y = 30;

tripod_thick = 20;
tripod_screw_thick = 2;

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
            translate([x, y, -0.1]) {
                cylinder(d = hole_d, h = frame_thickness + 0.2);
                translate([0,0, 0 + screw_thickness])
                    cylinder(d = hole_d * 2, h = frame_thickness + 0.2);
            }
        }
    }

    translate([0, 68, frame_thickness])
    write_text(revision_string);
    
    // connectors
    con_dx = frame_margin *2;
    con_dy = 60; 
    con_dz = frame_thickness * 2;
    con_x = -(inner_w + con_dx + frame_thickness ) /2 ;
    con_y = -10;
    con_z = 2;
    translate([con_x, con_y, con_z]) cube([con_dx, con_dy, con_dz]);

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
module camera_plate(
    hole_dx = 21,
    hole_dy = 12.5,
    hole_d = 2.2,
    plate_w = 30,
    plate_h = 30,
    plate_t = 3,
    standoff_od = 5.0,
    standoff_h = 4.0
) {
    difference() {
        union() {
            // base plate
            translate([-plate_w/2, -plate_h/2, 0])
                cube([plate_w, plate_h, plate_t]);

            // standoff tubes above the plate
            for (x = [-hole_dx/2, hole_dx/2],
                 y = [-hole_dy/2, hole_dy/2]) {
                translate([x, y, plate_t])
                    cylinder(d = standoff_od, h = standoff_h);
            }
        }

        // through holes through both plate and standoffs
        for (x = [-hole_dx/2, hole_dx/2],
             y = [-hole_dy/2, hole_dy/2]) {
            translate([x, y, -0.1])
                cylinder(d = hole_d, h = plate_t + standoff_h + 0.2);
        }
    }
}




module tripod() {
    cube_x = 40;
    translate([0,0,0]) {
        difference() {
            translate([-cube_x/2,-10, 0]) cube([cube_x, 25, tripod_thick]);
            translate([0, 0, -1]) cylinder(h = tripod_thick +1, d = 7);
            translate([0, 0, tripod_screw_thick]) cylinder(h = tripod_thick + 1, d = 14, $fn = 6);
        }
        translate([0, 0, elevator_y/2 -10])
        translate([(-cube_x )/2,  15 - frame_thickness, 10]) cube([cube_x , frame_thickness, elevator_y ]);
    }
    

    
}


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
if (view == "tripod") {
  tripod();
}

if (view == "camera_plate") {
  // flat("part");
  camera_plate();  
}


if (view == "assembly") { 
   echo("asda"); 
   translate([0, -85 -elevator_y, 15])rotate([-90,0,0]) tripod();
   frame();
}


