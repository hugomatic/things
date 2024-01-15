$fn = 64;
view = "assembly"; // [assembly, plate]

letter_size = 6;
revision_string = "1234567";


// hole diameter (3 inches)
screen_hole_dia = 76.2;
screen_z = 0.5;
screen_thick = 2; // 0.25;
screen_hole_thick = 2.5;// 0.75;
cross_thick_y = 3;
cross_thick_z = 15;

tube_thick= 5;
tube_height = 36;

top_thick = 7;
mag_height = 6;
mag_hole_dia = 22;
mag_screw_hole_dia = 5;

top_inner_dia = 113;
top_rim_x = 4;
top_rim_z = 2;

module magnet(depth) {
  shim = 2;
  translate([0,0,-depth-shim]) {
    cylinder(r=mag_screw_hole_dia /2 , h=depth+ 2 * shim);
  }
  z1 = top_thick - mag_height;
  translate([0,0,z1])
  cylinder(r=mag_hole_dia/2, h = top_thick + shim);
}

module magnets() {
  mag_rad = top_inner_dia/2 - mag_hole_dia/2 ;
  z = tube_height;
  translate([mag_rad,0,z]) magnet(top_thick);
  rotate([0,0,90])translate([mag_rad,0,z]) magnet(top_thick);
  rotate([0,0,270])translate([mag_rad,0,z]) magnet(top_thick);
  rotate([0,0,180])translate([mag_rad,0,z]) magnet(top_thick);
}

module tube(r1, r2, h) {
  shim = 1;
  difference() {
    cylinder(r=r1, h = h);
    translate([0,0,-shim]) cylinder(r=r2, h = h+ 2 *shim);
  }
}

module rim() {
  // rim

  z = tube_height;
  r1r = top_inner_dia /2 + top_rim_x;
  r2r = r1r - top_rim_x;
  dzr = top_rim_z + top_thick;
  translate([0,0,z]) {
    tube( r1r, r2r, dzr);
  }


}

module top_positive() {
  r1 = top_inner_dia /2;
  r2 = screen_hole_dia /2 - tube_thick;
  echo (r1, "r2", r2);
  dz = top_thick;
  z = tube_height;
  translate([0,0,z]) {
    tube( r1, r2, dz);
  }
  rim();
}

module top_negative() {
  magnets();
}


module top() {
  difference() {
    top_positive();
    top_negative();
  }
}

module body() {

  r1 = screen_hole_dia /2;
  r2 = r1 - tube_thick;
  z  = tube_height;
  tube(r1 , r2, z);

}

module screen_positive() {
  r = screen_hole_dia / 2;
  h = screen_z;
  cylinder(r=r, h=h);

  dx = screen_hole_dia - tube_thick;
  dy = cross_thick_y;
  dz = cross_thick_z;

  x = -screen_hole_dia/2;
  translate([0, 0, dz/2]) {
    cube([dx, dy, dz], center=true);
    rotate([0,0,90])cube([dx, dy, dz], center=true);
  }
}


module screen_negative() {

  // the square holes
  r = screen_hole_dia / 2;
  dx = screen_hole_thick;
  dy = screen_hole_thick;
  dz = screen_z * 3;
  step = screen_hole_thick + screen_thick;

  n = screen_hole_dia / step;
  for (i = [0:n]) {
    for (j = [0:n]) {
      translate([j*step - r, i*step-r, 0]) cube([dx, dy, dz], center= true);
    }
  }

}

module screen() {
  difference()
  {
    screen_positive();
    screen_negative();
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

module flat(part_name, x=0, y=0, angle=0) {
  if (part_name == "part") {
    rotate([180,0,0]) part();
  }
}



if (view == "part") {
  part();
}

if (view == "plate") {
  flat("part");
}

if (view == "assembly") {
  screen();
  body();
  translate([0,0,0])top();
}

