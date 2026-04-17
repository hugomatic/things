$fn = 16;
view = "assembly"; // [assembly, plate]

letter_size = 6;
revision_string = "1234567";

part_dx = 780;
part_dy = 40;
part_dz = 2;

comb_dx = 2;
comb_dy = 50;
comb_dz = 1;
comb_gap = 0.25;

hole4_x = 750;
hole3_x = 525;
hole2_x = 275;
hole1_x = 45;

holes_x = [part_dx - hole4_x, part_dx - hole3_x, part_dx - hole2_x, part_dx -hole1_x];

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

module comb_along_x(dx, comb_dx, comb_dy, comb_dz, comb_gap) {
    pitch = comb_dx + comb_gap;
    n = floor((dx + comb_gap) / pitch);

    for (i = [0 : n ]) {
        translate([i * pitch, 0, 0])
            cube([comb_dx, comb_dy, comb_dz]);
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

  // comb section
  translate([dx * i, -comb_dy,0])
    comb_along_x(dx, comb_dx, comb_dy, comb_dz, comb_gap);





}

module holes_4(holes_x, r=2, y=0, z=0) {
    for (i = [0:3]) {
        translate([holes_x[i] - 1, y, z])
            cylinder(h = 12, r = r);
    }
}

module door_sweep_negative(i) {

  cut_dx = part_dx /4;

  tx = i * cut_dx + cut_dx/2;
  translate([tx, 0, part_dz]) write_text(revision_string);

  translate([tx, 10, part_dz]) write_text(str(i+1));

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
        translate([i * -part_dx /4, i * 100, 0])  door_sweep(i);
    }

}


