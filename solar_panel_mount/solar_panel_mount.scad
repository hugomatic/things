$fn = 64;
view = "assembly"; // [assembly, plate, laser]

letter_size = 6;
revision_string = "1234567";

two_by_four = 40;

thick = 7;


arm_screw_dia = 5;
arm_dx1 = 62;
arm_dx2 = 180;
arm_dy1 = 80;
arm_dy2 = 80;

mount_bolts_y = 120;
mount_screw_dia = 5;

tab_h = 60;
tab_x = 18;
tab_h2 = 10;
arm_screw_dx = 30;
arm_screw_y = 20;


mount_y = 160;
mount_z = 80;



arm_dz = thick;


module write_text(string) {
    shim = 0.1;
    z0 = - thick/2 -  shim;
    dz= thick + 2 * shim;
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

module arm_positive() {

    shim = 0.1;

    p1 = [0,0, -thick /2];
    s1 = [arm_dx1, arm_dy1 + arm_dy2, thick];
    translate(p1)cube(s1);

    p2 = p1;
    s2 = [arm_dx1 + arm_dx2, arm_dy2, thick];
    translate(p2)cube(s2);

    //
    p3 = [0, 10, -thick/2];
    s3 = [s2[0] + thick + shim + tab_x, tab_h, thick];
    translate(p3)
        for ( i = [0:1:0])
            translate([0,i*(tab_h +  tab_h2),0])cube(s3);
}


module arm_negative() {
  shim = 0.1;
  translate([40,20,0])
    rotate([0,0,0])write_text(revision_string);

  // screw
  p = [(arm_dx1 + arm_screw_dx) /2,
       arm_dy1 + arm_dy2 - arm_screw_y,
       -thick/2 -shim];

  translate(p) {
      cylinder(d=arm_screw_dia, h=thick + 2 * shim);
      translate([-arm_screw_dx,0,0]) cylinder(d=5, h=thick + 2 * shim);
  }

  lynch_pin();
}


module arm() {
  difference() {
    arm_positive();
    arm_negative();
  }
}

module mount_positive() {
  p = [arm_dx1 + arm_dx2,
       0,
       -mount_z/2  + two_by_four / 2 + thick/2 ] ;  // two_by_four];
  s = [thick, mount_y, mount_z];
  translate(p) cube(s);

}

module lynch_pin() {
  pin_y = 30;
  pin_z = 30;
  p = [arm_dx1 + arm_dx2+thick,
       25,
       -mount_z/2  + two_by_four / 2 + thick/2  ] ;
  s = [thick, pin_y, pin_z];
  s1 = [thick, pin_y+30, 10];
  translate(p) {
    cube(s);
    translate([0,-15,0]) cube(s1);
  }
}


module mount_negative(){
    arms();
    mount_bolts();
}


module mount_bolts() {
  shim = 0.1;
  h = thick + 2 * shim;
  x = -shim + arm_dx1 + arm_dx2;


  z = (two_by_four + thick)/2;

  translate([x, mount_bolts_y, z] )rotate([0,90,0])
    rotate([0,0,90]) bolt_circle(0, 0, 54.85, mount_screw_dia, h);

}

module mount() {
  difference() {
    mount_positive();
    mount_negative();
  }
}

module flat(arm_name, x=0, y=0, angle=0) {
  if (arm_name == "arm") {
    rotate([180,0,0]) arm();
  }
}

module arms() {
  z = thick + two_by_four;
  arm();
  translate([0,0,z]) arm();

}

module assembly() {
  arms();
  color("red")mount();
  color("blue")lynch_pin();
}

module bolt_circle(x, y, d, hole_d, h) {
    // Calculate the positions of the three holes
    angle = 360 / 3; // 120 degrees between each hole
    for (i = [0:2]) {
        theta = i * angle;
        hole_x = x + (d / 2) * cos(theta);
        hole_y = y + (d / 2) * sin(theta);
        echo("hole", hole_x, hole_y);
        // Generate the cylinder for each hole
        translate([hole_x, hole_y, 0])
            cylinder(h, hole_d/2, hole_d/2);
    }
}

if (view == "arm") {
  arm();
}

if (view == "plate") {
    arm();

    translate([290, 280, 0])
     rotate([0,0,180])
        arm();

    rotate([0,90,90])
        translate([-(arm_dx1 + arm_dx2) - thick /2, -225, 100]) mount();

    rotate([0,90,90])
      translate([-(arm_dx1 + arm_dx2) - thick - thick/2, -70, 180 + 2.5]){
         lynch_pin();
         translate([0,-100,0]) lynch_pin();
      }

}

if (view == "assembly") {
  assembly();
}

