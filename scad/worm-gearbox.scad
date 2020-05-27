
use <thread_lib/Thread_Library.scad>
use <MCAD/involute_gears.scad>


print = "worm";
print = "spur";
print = "shim";
print = "cage";
print = "nothing";

draft = false;
$fs = draft ? 1 : 0.1;
$fa = 2;

clearance = 0.15;
q = 0.02;
PI = 3.141592653589793;

shaft_radius = 2.0 / 2;

spur_teeth = 10;
spur_pitch_radius = 8;
spur_addendum = 1 / ( spur_teeth / (spur_pitch_radius*2) );
spur_half_tooth = 360 /  spur_teeth / 2;
spur_thickness = 6;
shim_radius = shaft_radius + 2;

worm_length = 20;
worm_pitch_radius = 5;
worm_pitch = 2 * PI * spur_pitch_radius / spur_teeth; // Axial distance that worm "tooth" will travel with one tooth of the spur
worm_amplitude = worm_pitch * 0.5 * 0.5; // Distance from pitch_radius to either peak or trough
worm_tip_radius = worm_pitch_radius + worm_amplitude; // Radial distance from center to worm gear to furthest point.  Not really sure how this should be calculated
worm_shaft_radius = worm_pitch_radius - worm_amplitude - clearance*worm_amplitude*2;

between_shafts = worm_pitch_radius + spur_pitch_radius + worm_pitch*0;

angle = $t * 360; // For animation
fudge = 3;


module part( name, color= "white" )
{
  if ( print=="nothing" || print== name )
  color( color)
    child();
}


module chamfered_square( width, height, corner_radius= 1)
{
  hull()
  for( y= [ -1, +1 ])
  for( x= [ -1, +1 ])
  translate([ (width/2 - corner_radius)*x, (height/2 - corner_radius)*y ])
    circle( r= corner_radius);
}


module chamfered_cube( size, corner_radius= 1)
{
  linear_extrude( height= size[2], center=true)
    chamfered_square( size[0], size[1], corner_radius );
}


module cage()
{
  wall_thickness = 1.5;
  above_worm_shaft = worm_tip_radius + wall_thickness;
  below_worm_shaft = worm_shaft_radius + clearance*2 + (spur_pitch_radius+spur_addendum)*2 + clearance*2;
  cavity_size = [
    worm_tip_radius * 2,
    worm_length,
    above_worm_shaft + below_worm_shaft
  ] + [ 1, 2, 0] * clearance;
  envelope_size = cavity_size + [ wall_thickness*2, wall_thickness*2, wall_thickness ];

  difference()
  {
    translate([ 0, 0, -( cavity_size[2]/2 + wall_thickness/2) + above_worm_shaft ])
    difference()
    {
      // Outer surface
      chamfered_cube( envelope_size, wall_thickness);
      // Inner surface
      translate([ 0, 0, wall_thickness/2+q ])
        chamfered_cube( cavity_size, 0.3);
    }
    // Hole for worm shaft
    rotate([ 90, 0, 0 ])  // Along Y
      cylinder( r= shaft_radius + clearance*2, h=99, center=true);
    // Hole for spur shaft
    translate([ 0, 0, -between_shafts ])
    rotate([ 0, 90, 0 ])  // Along X
      cylinder( r= shaft_radius + clearance*2, h=99, center=true);
    // Holes so that gears can be seen operating
    mirror([0,0,1])
    {
      rotate([ 0, 90, 0 ]) // to lie along X
        chamfered_cube( [ worm_pitch_radius*2, cavity_size[1], 99 ], 2 );
      translate([ 0, 0, between_shafts ])
      rotate([ 90, 0, 0 ]) // to lie along Y
        chamfered_cube( [ cavity_size[0], spur_pitch_radius*2 - 2, 99 ], 2 );
    }
  }
}


part("worm", "aqua")
{
  rotate([ print=="worm" ? 0 : -90, 0, 0 ])
  difference()
  {
    *cylinder( r= worm_tip_radius, h= worm_length, center=true);  // Envelope
    *cylinder( r= worm_shaft_radius, h= worm_length, center=true);  // Envelope of shaft
    translate([ 0, 0, -worm_length/2 ]) // Center on Z
    rotate([ 0, 0, 270+angle ]) // Mesh with spur and animate
      trapezoidThread(
        length= worm_length,            // Axial length of the threaded rod
        pitch= worm_pitch,              // Axial distance from crest to crest
        pitchRadius= worm_pitch_radius, // Radial distance from center to mid-profile
        threadHeightToPitch= 0.5,       // Ratio between the height of the profile and the pitch
                                        // Std value for Acme or metric lead screw is 0.5
        profileRatio= 0.5,              // Ratio between the lengths of the raised part of the profile and the pitch
                                        // Std value for Acme or metric lead screw is 0.5
        // NOTE: When threadAngle was too high ( 40) I got invalid geometry
        threadAngle= 30,                // Angle between the two faces of the thread
                                        // Std value for Acme is 29 or for metric lead screw is 30
        RH= true,                       // true/false the thread winds clockwise looking along shaft, i.e.follows the Right Hand Rule
        clearance= clearance,           // Radial clearance, normalized to thread height
        backlash= 0.1,                  // Axial clearance, normalized to pitch
        stepsPerTurn= draft ? 12 : 48   // Number of slices to create per turn
      );
    // Shaft hole
    cylinder( r= shaft_radius + clearance, h=99, center=true);
  }
}

translate([ 0, 0, -between_shafts ])
rotate([ 0, print=="spur" || print=="shim" ? 0 : 90, 0 ]) // Orient for printing or animation
{
  part("shim")
  mirror([0,0,1])
  assign( os= spur_thickness/2 )
  assign( t= worm_tip_radius - os )
  translate([0,0, os ])
  linear_extrude( height= t)
  difference()
  {
    circle( r= shim_radius);
    circle( r= shaft_radius + clearance);
  }

  part("spur", "orange")
  rotate([ 0, 0, spur_half_tooth + fudge + angle / spur_teeth ]) // Animate
  {
    *cylinder( r= spur_pitch_radius+spur_addendum, h=10, center=true); // Envelope
    translate([ 0, 0, -spur_thickness/2 ])  // Center on Z
    gear(
      number_of_teeth= spur_teeth,
      circular_pitch= 360 * spur_pitch_radius / spur_teeth,
      pressure_angle= 30,
      clearance= 0,
      gear_thickness= spur_thickness,
      rim_thickness= spur_thickness,
      rim_width= 5,
      hub_thickness= spur_thickness/2 + worm_tip_radius,
      hub_diameter= shim_radius*2,
      bore_diameter= ( shaft_radius + clearance)*2,
      circles= 0,
      backlash= 0.1,
      twist= -2,
      involute_facets= 0,
      flat= false
    );
  }
}

part("cage", "moccasin")
  cage();

