% -*- mode: slang; mode: fold; -*-

% Creates a rectangle with the LL corner at the origin
define xfig_new_rectangle (dx, dy)
{
   return xfig_new_polygon (vector([0,dx,dx,0,0], [0,0,dy,dy,0], [0,0,0,0,0]));
}

define xfig_new_grid (nx, ny, dx, dy)
{
   variable lenx, leny;
   variable X;
   
   leny = ny * dy;
   lenx = nx * dx;

   variable border = xfig_new_rectangle (lenx, leny);
   variable list = xfig_new_polyline_list ();

   nx++;
   ny++;

   variable xs, ys, zs, x, y;
   x = 0;
   ys = [0,leny];
   zs = [0,0];
   loop (nx)
     {
	X = vector ([x,x], ys, zs);
	list.insert (X);
	x += dx;
     }
   
   xs = [0, lenx];
   y = 0;
   loop (ny)
     {
	X = vector (xs, [y,y], zs);
	list.insert (X);
	y += dy;
     }
   
   %return list;
   return xfig_new_compound (border, list);
}

%}}}

define xfig_new_block (dx, dy, dz)
{
   variable block = xfig_new_polygon_list ();   
   variable X, p, obj;

   variable zeros = [0,0,0,0,0];
   % Bottom
   X = vector ([0, 0, dx, dx, 0], [0, dy, dy, 0, 0], zeros);
   block.insert (xfig_new_polygon(X));

   % Top
   X = vector ([0, dx, dx, 0, 0], [0, 0, dy, dy, 0], [dz, dz, dz, dz, dz]);
   block.insert (xfig_new_polygon(X));

   % Left
   X = vector ([0, dx, dx, 0, 0], zeros, [0, 0, dz, dz, 0]);
   block.insert (xfig_new_polygon(X));

   % Front
   X = vector ([dx, dx, dx, dx, dx], [0, dy, dy, 0, 0], [0, 0, dz, dz, 0]);
   block.insert (xfig_new_polygon(X));

   % Back
   X = vector (zeros, [0, 0, dy, dy, 0], [0, dz, dz, 0, 0]);
   block.insert (xfig_new_polygon(X));

   % Right
   X = vector ([0, 0, dx, dx, 0], [dy, dy, dy, dy, dy], [0, dz, dz, 0, 0]);
   block.insert (xfig_new_polygon(X));

   return block;
}

#ifnexists urand
private variable Fast_Random = _time ();
private define urand (n)
{
   variable x = Double_Type[n];
   _for (0, n-1, 1)
     {
	variable i = ();
	Fast_Random = Fast_Random * 69069U + 1013904243U;
	x[i] = Fast_Random/4294967296.0;
     }
   return x;
}
#endif

define xfig_new_random_polyline (dx, dy, dz, max_points)
{
   return xfig_new_ellipse (dx, dy);
   variable x, y, z;
   x = 2*(0.5-urand(max_points));
   y = 2*(0.5-urand(max_points));
   z = 2*(0.5-urand(max_points));
   
   variable i = where (x*x + y*y + z*z < 1.0);
   return xfig_new_polyline (vector (dx*x[i], dy*y[i], dz*z[i]));
}

% Created photon will have head at the origin and tail at dX
define xfig_new_photon (dX, amp, period)
{
   dX = vector_chs (dX);
   variable x, y, z, t;
   variable len = vector_norm (dX);
   z = [0:len:period/(10*len)];
   t = z*(2*PI/period);

   % For the arrow to look ok, make the amp fall off near the end
   amp *= (1.0 - exp ((z-len)/(3*period)));
   x = amp*cos (t);
   y = amp*sin (t);
   variable v = vector (x, y, z);
   variable n = crossprod(vector(0,0,1), dX);
   normalize_vector (n);
   variable cos_theta = dX.z/len;
   v = vector_rotate (v, n, acos (cos_theta));
   variable photon = xfig_new_polyline (v);
   variable a = xfig_new_arrow_head (0.5*period, period, dX);
   dX = vector_chs (dX);
   photon.translate (dX);
   a.translate (dX*(period/len));
   return xfig_new_compound (photon, a);
}

% Neither of these functions work too well  --- avoid them
define xfig_new_labeled_arrow (dX, label)
{
   variable height = 0.1, width = 0.05;

   variable p = xfig_new_polyline (vector([0,dX.x], [0,dX.y], [0,dX.z])
				   ;; __qualifiers);
   variable a = xfig_new_arrow_head (width, height, dX;; __qualifiers);
   a.translate ((1.0-height)*dX);
   if (label != NULL)
     {
	label = xfig_new_text (label ;;__qualifiers);
	variable dx, dy;
	(dx, dy) = label.get_pict_bbox ();
	label.translate (1.05*dX + vector (dX.x*dx, dy, 0));
     }
   return xfig_new_compound (p, a, label);
}
define xfig_new_3d_axis (xlabel, ylabel, zlabel)
{
   variable e1 = xfig_new_labeled_arrow (vector(1,0,0), xlabel;; __qualifiers);
   variable e2 = xfig_new_labeled_arrow (vector(0,1,0), ylabel;; __qualifiers);
   variable e3 = xfig_new_labeled_arrow (vector(0,0,1), zlabel;; __qualifiers);
   return xfig_new_compound (e1, e2, e3);
}

define xfig_new_hedgehog (radius, n)
{
   variable h = xfig_new_polyline_list ();
   variable phis = 2*PI*urand (n);
   variable thetas = acos (2.0*urand (n)-1);
   variable xs = sin(thetas);
   variable ys = xs*sin(phis); xs *= cos(phis);
   variable zs = cos(thetas);

   _for (0, n-1, 1)
     {
	variable i = ();
	variable x = xs[i], y = ys[i], z = zs[i];
	h.insert (vector ([-x,x], [-y,y], [-z,z]));
     }
   return h;
}



define xfig_new_polyline_with_arrow (X, width, height)
{
   variable x = X.x, y = X.y, z = X.z;
   if (length (x) < 2)
     verror ("xfig_new_arrow: need at least 2 points");

   variable line = xfig_new_polyline (X);

   X = vector (x[-1], y[-1], z[-1]);
   variable dX = vector_diff (X, vector (x[-2], y[-2], z[-2]));

   variable a = xfig_new_arrow_head (width, height, dX);
   normalize_vector (dX);
   %xfig_translate_object (a, X);
   a.translate (vector_diff (X, vector_mul (height, dX)));
   return xfig_new_compound (line, a);
}

			      
