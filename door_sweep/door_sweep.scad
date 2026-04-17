$fn = 16;
view = "assembly"; // [assembly, plate]

letter_size = 6;
revision_string = "1234567";

part_dx = 780;
part_dy = 40;
part_dz = 2;


hole4_x = 750;
hole3_x = 525;
hole2_x = 275;
hole1_x = 45;

holes_x = [part_dx - hole4_x, part_dx - hole3_x, part_dx - hole2_x, part_dx -hole1_x];

dovetail_h = 60;
dovetail_size = dovetail_h /4;
dovetail_ratio = 1.4;
dovetail_rounding = dovetail_size /5;
dovetail_gap = 0.2;



module tooth() intersection() {
    $fn=160;
    translate([0, dovetail_gap/2])
    // STEP 3: Quad offset
    // external
    offset(dovetail_rounding) offset(-dovetail_rounding)
    // internal
    offset(-dovetail_rounding) offset(dovetail_rounding)
    // adding dovetail_rounding to sides to cancel radius when looping
    // STEP 1
    polygon([
        [-dovetail_size - dovetail_rounding, -dovetail_size/2], // left shoulder
        [-dovetail_size/2  * (2-dovetail_ratio), -dovetail_size/2], // left neck
        // STEP 2 (dovetail_ratio)
        [-dovetail_size*dovetail_ratio/2, dovetail_size/2], // left ear
        [dovetail_size*dovetail_ratio/2, dovetail_size/2], // right ear
        [dovetail_size/2 * (2-dovetail_ratio), -dovetail_size/2], // right neck

        [dovetail_size + dovetail_rounding, -dovetail_size/2], // right shoulder
        [dovetail_size + dovetail_rounding, -dovetail_size*2], // right bottom
        [-dovetail_size - dovetail_rounding, -dovetail_size*2], // left bottom
    ]);

    // shave off the rounded bit of the shoulders
    translate([-dovetail_size, -dovetail_size*4]) square([dovetail_size*2, dovetail_size*5]);
}


module tooth_cut() difference() {
    // STEP 4
    tooth();
    offset(-dovetail_gap) tooth();
    // STEP 5
    translate([-dovetail_size*2, -dovetail_size*5 - dovetail_size/2 - dovetail_gap/2, 0]) square([dovetail_size*4, dovetail_size*5]);
}


// this is done in 3D rather than 2D to allow for a taper -- this way the fit
// tightens as the teeth are pushed in, and the glue is squeezed instead of
// scraped
 module tooth_cut_3d() difference() {
    translate([dovetail_size, 0, -1])
    // STEP 6 & 7
    linear_extrude(dovetail_h, scale=dovetail_ratio, convexity=3)
    tooth_cut();
    // STEP 8
    // difference is used to constrain the edges to prevent overlap
    // I tried intersection (to do it in one pass) but performance TANKED!
    translate([-dovetail_size*2-0.01,-dovetail_size, -1]) linear_extrude(dovetail_h+2) square([dovetail_size*2, dovetail_size*2]);
    translate([dovetail_size*2+0.01,-dovetail_size, -1]) linear_extrude(dovetail_h+2) square([dovetail_size*2, dovetail_size*2]);
}

// will get at least length
module teeth_cut_3d(length) {
    n = ceil(length / (dovetail_size*2))+2;
    real_length = n * dovetail_size*2;

    // STEP 9
    for (i=[0:n-1])
        translate([i*dovetail_size*2 - real_length/2, 0]) tooth_cut_3d();

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


module door_sweep_positive(i){

  parts = 4;

  dx = part_dx/4;
  dy = part_dy;
  dz = part_dz;

  ax = (i) * dx;
  ay = -dy /2;
  az = 0;

  r = 20;
  translate([ax,ay,az]) {
      cube([dx, dy, dz]);
  }
  tab_dx = 30;
  tab_dy = part_dy/3;
  tab_dz = part_dz;

  y = -tab_dy /2;
  x = dx * i - tab_dx /2;
  z = 0;

  if (i==2)translate([x, y, z] ) cube([tab_dx, tab_dy, tab_dz]);
  if ((i == 0) || (i == 2)) translate([x + dx, y, z] ) cube([tab_dx, tab_dy, tab_dz]);



}

module holes_4(holes_x, r=2, y=0, z=0) {
    for (i = [0:3]) {
        translate([holes_x[i] - 1, y, z])
            cylinder(h = 12, r = r);
    }
}

module door_sweep_negative(i) {

  cut_dx = part_dx /4;
  // translate([1 * cut_dx, 0, 0]) rotate([0,0,90])teeth_cut_3d(300);
  // translate([2 * cut_dx, 0, 0]) rotate([0,0,90])teeth_cut_3d(300);
  // translate([3 * cut_dx, 0, 0]) rotate([0,0,90])teeth_cut_3d(300);

  translate([i * cut_dx + cut_dx/2, 0, part_dz]) write_text(revision_string);

  tab_dx = 30;
  tab_dy = part_dy/3;
  tab_dz = part_dz + 1;

  y = -tab_dy /2;
  x = cut_dx * i - tab_dx /2;
  z = -0.1;

  if ((i == 1) || (i==3))translate([x, y, z] ) cube([tab_dx, tab_dy, tab_dz]);
  if (i == 1) translate([x + cut_dx, y, z] ) cube([tab_dx, tab_dy, tab_dz]);


  holes_4(holes_x, r=2, y=0, z=-1);

}

module door_sweep(i) {
  difference() {
    door_sweep_positive(i);
    door_sweep_negative(i);
  }
}

module flat(part_name, x=0, y=0, angle=0) {
  if (part_name == "part") {
    rotate([180,0,0]) door_sweep();
  }
}



if (view == "part") {
  door_sweep();
}


if (view == "assembly") {
    for (i = [0:3]) {
        translate([0, 0, 0])  door_sweep(i);
    }

}

if (view == "plate") {
    for (i = [0:3]) {
        translate([0, i * 100, 0])  door_sweep(i);
    }

}


