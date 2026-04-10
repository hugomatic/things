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
  dx = part_dx;
  dy = part_dy;
  dz = part_dz;
  // top is at z=0
  x = -dx /2;
  y = -dy /2;
  z = -dz;

  r = 20;
  // translate([x,y,z]) {cube([dx, dy, dz]);}
  echo("part", dx,dy,r,dz);
  translate([0,0,-part_dz/2]) round_hull(dx,dy,r,dz);
}


module part_negative() {
  
  t = 5;  
  hole_z = 11;  
  hole_h = hole_z + 1;
    
  translate([0,0,-part_dz])
    rotate([0,180,0])write_text(revision_string);
    
  translate([0,0, -hole_z]) {
      cylinder(h=hole_h, d= 82);
  }
  translate([0,0, -hole_z - 2]) {
      translate([0, 50,0]) cylinder(h=hole_h, d= 15);
      translate([0,-50,0]) cylinder(h=hole_h, d= 15);
  }
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



if (view == "part") {
  part();
}

if (view == "plate") {
  flat("part");
}

if (view == "assembly") {
  part();
}

