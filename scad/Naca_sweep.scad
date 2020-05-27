// Naca4_sweep.scad - sweep library
// Code: Rudolf Huttary, Berlin 
// 1st release : June 2015
// last update: 2017.02.10
// commercial use prohibited

use <naca4.scad>

//example1(); 
//rotate([80, 180, 130])
//example(); 

// sweep from NACA1480 to NACA6480 (len = 230 mm, winding y,z = 80°
// sweeps generates a single polyhedron from multiple datasets
module example()
{
  N = 40; 
  sweep(gen_dat(N=5, dz=1,N=N), showslices = false); 
//  sweep(gen_dat(N=5, dz=1,N=N), showslices = true); 
  
  // specific generator function
  function gen_dat(M=10,dz=.1,N=10) = [for (i=[1:dz:M])   
    let( L = length(i))
    let( af = vec3D(
        airfoil_data([.1,.5,thickness(i)], L=length(i), N = N)))
    T_(-L/2, 0, (i+1)*2, af)];  // translate airfoil
  
  function thickness(i) = .5*sin(i*i)+.1; 
  function length(i) = (60+sin(12*(i-3))*30); 
}

module help() help_Naca_sweep(); 
module help_Naca_sweep()
{
  echo(str("\n\nNaca4_sweep library by Rudolf Huttary\n",
  "module poly(p)       // show 2D or 3D-polygon in 3D space\n",
  "List of signatures in lib:\n=================\n", 
  "sweep(dat, convexity = 5, showslices = false, close = false, planar_caps = false)  // dat - vec of vec3-polygons\n", 
  "function vec3D(v, z=0)  // expand vec2 to vec3",
  "function rot(w=0, p) // rotate vec2",
  "function T_(x=0, y=0, z=0, v) // translates vec of vec3\n", 
  "function R_(x=0, y=0, z=0, v) // rotates vec of vec3\n", 
  "function Rx_(x=0, v) // x-rotates vec of vec3\n", 
  "function Ry_(y=0, v) // y-rotates vec of vec3\n", 
  "function Rz_(z=0, v) // z-rotates vec of vec3\n", 
  "function T_(x=0, y=0, z=0, v) // translates vec of vec3\n", 
  "function Tx_(x=0, v) // x-translates vec of vec3\n", 
  "function Ry_(y=0, v) // y-translates vec of vec3\n", 
  "function Rz_(z=0, v) // z-translates vec of vec3\n", 
  "function S_(x=0, y=0, z=0, v) // scales vec of vec3\n", 
  "function Sx_(x=0, v) // x-translates vec of vec3\n", 
  "function Sy_(x=0, v) // y-translates vec of vec3\n", 
  "function Sz_(x=0, v) // z-translates vec of vec3\n",
  "function earcut(p)   // triangulates simple polygon p \n", 
  "function count(a, b) // sequence a to b as list\n",
  "=================\n")); 
}

module poly(p)
{
  p_ = (len(p[0])==2)?vec3D(p):p;
  polyhedron(p_, [count(0,len(p)-1)]); 
}

// Calculates a polyhedron based extrusion. 
// Expects a dataset defined as *non-selfintersecting* sequence of polygons that describes a extrusion trajectory
//  interchangable with skin()
// dat := vector of simple polygons, with polygon := vec of vec3, minimum 3 points per polygon expected
// use "planar_caps = true" only if triangulation of OpenSCAD works flawlessly
module sweep(dat, convexity = 5, showslices = false, close = false, planar_caps = true, convexity = 5) 
{
  n = len(dat);     // # datasets
  l = len(dat[0]);  // points per dataset 
  if(l<=3) echo("ERROR: sweep() expects more than 3 points per dataset"); 
  if (showslices)  for(i=dat) poly(i);
  else
  {
    obj = sweep_(dat, close=close, planar_caps=planar_caps); 
    polyhedron(obj[0], obj[1], convexity = convexity); 
  }
}

function sweep_(dat, close = false, planar_caps = true) = let(n=len(dat), l=len(dat[0]))
  let(first = planar_caps?[count(l-1, 0)]: facerev(earcut(dat[0])))
  let(last = planar_caps?[count((n-1)*l,(n)*l-1)]: faces_shift((n-1)*l, (earcut(dat[0])))) 
  let(faces = close?faces_sweep(l,n, close) :concat(first, last, faces_sweep(l,n))) 
  let(points = [for (i=[0:n-1], j=[0:l-1]) dat[i][j]]) // flatten points vector
[points, faces]; 

function count(a, b) = [for (i=[a:(a<b?1:-1):b]) i]; 

function faces_shift(d, dat) = [for (i=[0:len(dat)-1]) dat[i] + [d, d, d]]; 
  
//// knit polyhedron
  function faces_sweep(l, n=1, close = false) = 
      let(M = n*l, n1=close?n+1:n) 
      concat([[0,l,l-1]],   // first face
             [for (i=[0:l*(n1-1)-2], j = [0,1])
                j==0? [i, i+1, (i+l)%M] 
                    : [i+1, (i+l+1)%M, (i+l)%M]
             ]
             ,[[(n1*l-1)%M, (n1-1)*l-1, ((n1-1)*l)%M]
             ]); // last face
      ;
    
function facerev(dat) = [for (i=[0:len(dat)-1]) [dat[i][0],dat[i][2],dat[i][1]]]; 

// rekursive Algorithm used for triangulation of first and last face
function earcut(p, k=false, N = 100) = 
let(N_ = k?len(p):N)  // limit recursion at first call
let(k_ = k?k:[for (i=[0:len(p)-1]) i]) // init point index list
let(f = inner(p,k_))
(len(f[1])<3) || N==0 ? f[0] : concat(f[0], earcut(p,f[1], N-1)); 

function inner(p, k) = let(N = len(k))
 let(faces = [for(i=[0:2:N-2]) if(is_left(p[k[i]], p[k[i+1]], p[k[(i+2)%N]])) [k[i], k[i+1], k[(i+2)%N]]])
 let(done = [for(i=faces) i[1]])
 let(rest = [for(i=[1:N]) if (notin(k[i%N], done)) k[i%N]])
 [faces, rest];   

function notin(x,k) = [for(i=k) if (i==x) x] == []; 
     
// true if c is left of a--->b
function is_left(a, b, c) = abs(a[2]-b[2])<1e-10? is_leftz(a, b, c):abs(a[1]-b[1])<1e-10?is_lefty(a, b, c):is_leftx(a, b, c);
function is_leftz(a, b, c) = (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])<=0;    
function is_leftx(a, b, c) = (b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1])<=0;    
function is_lefty(a, b, c) = (b[2]-a[2])*(c[0]-a[0])-(b[0]-a[0])*(c[2]-a[2])<=0;    


//// vector and vector set operation stuff ///////////////////////
//// Expand 2D vector into 3D
function vec3D(v, z=0) = [for(i = [0:len(v)-1]) 
  len(v[i])==2?[v[i][0], v[i][1], z]:v[i]+[0, 0, z]]; 

// Translation - 1D, 2D, 3D point vector //////////////////////////
// vector along all axes
function T_(x=0, y=0, z=0, v) = let(x_ = (len(x)==3)?x:[x, y, z])
  [for (i=[0:len(v)-1]) T__(x_[0], x_[1], x_[2], p=v[i])]; 
/// vector along one axis
function Tx_(x=0, v) = T_(x=x, v=v); 
function Ty_(y=0, v) = T_(y=y, v=v); 
function Tz_(z=0, v) = T_(z=z, v=v); 
/// point along all axes 1D, 2D, 3D allowed
function T__(x=0, y=0, z=0, p) = len(p)==3?p+[x, y, z]:len(p)==2?p+[x, y]:p+x; 

//// Rotation - 2D, 3D point vector ///////////////////////////////////
// vector around all axes 
function R_(x=0, y=0, z=0, v) =             // 2D vectors allowed 
  let(x_ = (len(x)==3)?x:[x, y, z])
  len(v[0])==3?Rz_(x_[2], Ry_(x_[1], Rx_(x_[0], v))):
  [for(i = [0:len(v)-1]) rot(x_[2], v[i])];  
// vector around one axis
function Rx_(w, A) = A*[[1, 0, 0], [0, cos(w), sin(w)], [0, -sin(w), cos(w)]]; 
function Ry_(w, A) = A*[[cos(w), 0, sin(w)], [0, 1, 0], [-sin(w), 0, cos(w)]]; 
function Rz_(w, A) = A*[[cos(w), sin(w), 0], [-sin(w), cos(w), 0], [0, 0, 1]]; 


//// Scale - 2D, 3D point vector ///////////////////////////////////
// vector along all axes 
function S_(x=1, y=1, z=1, v) = 
  [for (i=[0:len(v)-1]) S__(x,y,z, v[i])]; 
// vector along one axis
function Sx_(x=0, v) = S_(x=x, v=v); 
function Sy_(y=0, v) = S_(y=y, v=v); 
function Sz_(z=0, v) = S_(z=z, v=v); 
// single point in 2D
function S__(x=1, y=1, z=1, p) = 
  len(p)==3?[p[0]*x, p[1]*y, p[2]*z]:len(p)==2?[p[0]*x+p[1]*y]:[p[0]*x]; 

 
 