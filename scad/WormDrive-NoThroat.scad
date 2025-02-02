use <thread_lib/Thread_Library.scad>
use <MCAD/involute_gears.scad>

numberTeeth=20;
pitchRadius=40;


length=40;
radius=10;
pitch=2*3.1415*pitchRadius/numberTeeth;

angle=360*$t;
offset=7.5;

distance=radius+pitchRadius+0.0*pitch;

translate([0,15,0])
{
translate([0,0,-length/2])
rotate([0,0,180+angle])
trapezoidThread( 
	length=length, 			// axial length of the threaded rod
	pitch=pitch,				 // axial distance from crest to crest
	pitchRadius=radius, 		// radial distance from center to mid-profile
	threadHeightToPitch=0.5, 	// ratio between the height of the profile and the pitch
						// std value for Acme or metric lead screw is 0.5
	profileRatio=0.5,			 // ratio between the lengths of the raised part of the profile and the pitch
						// std value for Acme or metric lead screw is 0.5
	threadAngle=40, 			// angle between the two faces of the thread
						// std value for Acme is 29 or for metric lead screw is 30
	RH=true, 				// true/false the thread winds clockwise looking along shaft, i.e.follows the Right Hand Rule
	clearance=0.1, 			// radial clearance, normalized to thread height
	backlash=0.1, 			// axial clearance, normalized to pitch
	stepsPerTurn=24 			// number of slices to create per turn
	);


translate([-5,-distance,0])
rotate([0,90,0])
rotate([0,0,offset-angle/numberTeeth])
gear ( 
	number_of_teeth=numberTeeth,
	circular_pitch=360*pitchRadius/numberTeeth,
	pressure_angle=20,
	clearance = 0,
	gear_thickness=10,
	rim_thickness=10,
	rim_width=5,
	hub_thickness=10,
	hub_diameter=10,
	bore_diameter=5,
	circles=0,
	backlash=0.1,
	twist=-2,
	involute_facets=0,
	flat=false);
}