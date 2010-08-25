% clipping routines

private define intersect (x0, dx, y0, dy, a, da, b, db)
{
   variable s = Double_Type[length(x0)], t = @s;
   variable den = dx*db - dy*da;
   variable i = where (den == 0);
   s[i] = -1; t[i] = -1;
   i = where (den != 0);
   variable alpha = a-x0;
   variable beta = b-y0;
   den = den[i];
   s[i] = (dy*alpha-dx*beta)[i]/den;
   t[i] = (db*alpha-da*beta)[i]/den;
   return s, t;
}

private define project_to_boundary (x0, x1, xmin, xmax, delta_is_zero)
{
   variable i = where (isinf(x0) and (delta_is_zero));
   ifnot (length (i))
     return;

   variable j = where ((x0[i] < xmin) and (x1[i] > xmin));
   x0[i[j]] = xmin;
   j = where ((x0[i] > xmax) and (x1[i] < xmax));
   x0[i[j]] = xmax;
}

% Here the line segment is represented by (x0,y0) -> (x1,y1).  These
% coordinates can be infinite.  Since we are interested in where these
% segments intersect within the box defined by (xmin,xmax,ymin,ymax),
% project the line segment to the box.
private define project_infinite_values (x0, x1, y0, y1, xmin, xmax, ymin, ymax)
{
   variable delta_is_zero = abs((y1-y0) < 1e-6*(ymax-ymin));
   project_to_boundary (x0, x1, xmin, xmax, delta_is_zero);
   project_to_boundary (x1, x0, xmin, xmax, delta_is_zero);
   delta_is_zero = abs((x1-x0) < 1e-6*(xmax-xmin));
   project_to_boundary (y0, y1, ymin, ymax, delta_is_zero);
   project_to_boundary (y1, y0, ymin, ymax, delta_is_zero);
}


%!%+
%\function{xfig_clip_polyline2d}
%\synopsis{Clip a list of 2d line segments}
%\usage{list = xfig_clip_polyline2d (x[], y[], xmin, xmax, ymin, ymax)}
%\description
% This function clips a polyline composed individual line segments that run from
% (x_i,y_i) to (x_{i+1},y_{i+1}) at the boundaries of the window defined by the
% \exmp{xmin}, \exmp{xmax}, \exmp{ymin}, and \exmp{ymax} parameters.  The result
% is returned as an xfig polyline object.
%\notes
% This function should be used if the order of the line segments does not matter.
% Otherwise, the \sfun{xfig_clip_polygon2d} function should be used.
%\seealso{xfig_clip_polygon2d, xfig_new_polyline_list}
%!%-
define xfig_clip_polyline2d (x, y, xmin, xmax, ymin, ymax)
{
   variable is_outside;
   is_outside = ((x < xmin) or (x > xmax) or (y < ymin) or (y > ymax));

   if (length (where(is_outside)) == 0)
     return xfig_new_polyline (vector(x,y,0*x));

   variable list = xfig_new_polyline_list ();
   % Suppose is_outside looks like:
   %   00001000110000111
   % Separate the line segments into those that lie in the region and those
   % that are outside.
   variable len = length (x);
   if (len < 2)
     return list;

   variable bad = where (is_outside);
   variable i, j, i0;
   i0 = 0;
   variable line;
   foreach (bad)
     {
	i = ();
	if (i - i0 >= 2)
	  {
	     j = [i0:i-1];
	     list.insert (vector (x[j],y[j],0.0*j));
	  }
	i0 = i + 1;
     }
   % This segment was not picked up by the above loop
   if (is_outside[len-1] == 0)
     {
	if (i0 != len-1)
	  {
	     j = [i0:len-1];
	     list.insert (vector(x[j],y[j],0.0*j));
	  }
     }

   % Now deal with the segments that involve outside points
   i = [0:len-2];
   variable x0 = x[i], y0 = y[i];
   variable is_outside0 = is_outside[i];
   i = [1:len-1];
   variable x1 = x[i], y1 = y[i];
   variable is_outside1 = is_outside[i];
   % Suppose is_outside looks like:
   %   is_outside:  00001000110000111
   % Then:
   %   is_outside0: 0000100011000011
   %   is_outside1: 0001000110000111
   % The segments that we want to deal with are:
   %                0001100111000111
   bad = where (is_outside0 or is_outside1);
   x0 = x0[bad]; x1 = x1[bad];
   y0 = y0[bad]; y1 = y1[bad];
   is_outside0 = is_outside0[bad];
   is_outside1 = is_outside1[bad];

   project_infinite_values (x0, x1, y0, y1, xmin, xmax, ymin, ymax);

#iffalse
   % swap 0 <--> 1 such that 0 represents the inside point
   i = where (0 == is_outside1);
   (x0[i], x1[i]) = (x1[i], x0[i]);
   (y0[i], y1[i]) = (y1[i], y0[i]);
   (is_outside0[i], is_outside1[i]) = (is_outside1[i], is_outside0[i]);
#endif
   variable dx = x1 - x0;
   variable dy = y1 - y0;
   variable a = [xmin, xmax, xmax, xmin];
   variable b = [ymin, ymin, ymax, ymax];
   variable da = [xmax-xmin, 0, xmin-xmax, 0];
   variable db = [0, ymax-ymin, 0, ymin-ymax];
   variable s = Array_Type[4], t = Array_Type[4], is_intersect = Array_Type[4];
   variable ss, tt;
   _for (0, 3, 1)
     {
	i = ();
	(ss, tt) = intersect (x0, dx, y0, dy, a[i], da[i], b[i], db[i]);
	is_intersect[i] = ((ss>=0)and (ss<=1)and (tt>=0)and(tt<=1));
	s[i] = ss;
	t[i] = tt;
     }

   _for (0, length(x0)-1, 1)
     {
	i = ();
	variable min_t = 2, max_t = -1;

	if (is_outside0[i] == 0)
	  min_t = 0;
	if (is_outside1[i] == 0)
	  max_t = 1;

	if ((is_outside0[i] == 0) and (is_outside1[i] == 0))
	  vmessage ("NO");

	variable num_intersects = 0;
	_for (0, 3, 1)
	  {
	     j = ();
	     if (is_intersect[j][i] == 0)
	       continue;

	     tt = t[j][i];
	     if (tt < min_t) min_t = tt;
	     if (tt > max_t) max_t = tt;
	     num_intersects++;
	  }
	if ((min_t < 0) or (min_t > 1) or (max_t < 0) or (max_t > 1))
	  continue;

	variable x0_i = x0[i];
	variable y0_i = y0[i];
	variable dx_i = dx[i];
	variable dy_i = dy[i];
	variable x1_i = x0_i + dx_i*max_t;
	variable y1_i = y0_i + dy_i*max_t;
	x0_i += dx_i*min_t;
	y0_i += dy_i*min_t;

	if (x0_i > xmax) x0_i = xmax;
	if (x0_i < xmin) x0_i = xmin;
	if (y0_i > ymax) y0_i = ymax;
	if (y0_i < ymin) y0_i = ymin;
	if (x1_i > xmax) x1_i = xmax;
	if (x1_i < xmin) x1_i = xmin;
	if (y1_i > ymax) y1_i = ymax;
	if (y1_i < ymin) y1_i = ymin;

	if (length (where ((x0_i < xmin-0.001) or (x0_i > xmax+0.001)
			   or (x1_i < xmin-0.001) or (x1_i > xmax+0.001)
			   or (y0_i < ymin-0.001) or (y0_i > ymax+0.001)
			   or (y1_i < ymin-0.001) or (y1_i > ymax+0.001))))
	  {
	     vmessage ("Uh oh--- line not clipped: min_t = %g, max_t=%g, is_outside0=%d, is_outside1=%d, num_intersects=%d",
		       min_t, max_t, is_outside0[i], is_outside1[i], num_intersects);
	     message ("box from ($xmin,$ymin)->($xmax,$ymax)"$);
	     message ("($x0_i,$y0_i)->($x1_i,$y1_i)"$);
	     vmessage ("Orig coords: %g,%g -> %g,%g",x0[i],y0[i],x1[i],y1[i]);
	  }

	list.insert (vector ([x0_i, x1_i], [y0_i, y1_i], [0,0]));
     }

   return list;
}

% This algorithm is based uses the Sutherland-Hodgman method
private define intersect_x (x0, y0, x1, y1, x)
{
   variable d0 = x - x0;
   variable d1 = x1 - x;
   variable den = d0+d1;
   if (den == 0)
     return (x, y0);
   return x, (d0*y1 + d1*y0)/den;
}

private define intersect_y (x0, y0, x1, y1, y)
{
   variable d0 = y - y0;
   variable d1 = y1 - y;
   variable den = d0+d1;
   if (den == 0)
     return (x0, y);
   return (d0*x1 + d1*x0)/den, y;
}

private define clip_1 (x, y, is_outside, intersect, a)
{
   variable fx, fy, sx, sy, xi, yi, xx, yy;

   variable n = length (x);
   if (n == 0)
     return x, y;

   variable new_x = {};
   variable new_y = {};
   variable last_outside = is_outside[0];

   fx = x[0]; fy = y[0];
   sx = fx, sy = fy;
   _for (0, n-1, 1)
     {
	variable i = ();
	variable io = is_outside[i];
	if (io == last_outside)
	  {
	     sx = x[i];
	     sy = y[i];
	  }
	else
	  {
	     last_outside = io;
	     xi = x[i]; yi = y[i];
	     (xx, yy) = (@intersect) (sx, sy, xi, yi, a);
	     list_append (new_x, xx);
	     list_append (new_y, yy);
	     sx = xi;
	     sy = yi;
	  }
	if (last_outside == 0)
	  {
	     list_append (new_x, sx);
	     list_append (new_y, sy);
	  }
     }

   if (length (new_x) and (last_outside != is_outside[0]))
     {
	(xx, yy) = (@intersect) (sx, sy, fx, fy, a);
	list_append (new_x, xx);
	list_append (new_y, yy);
     }
   return new_x, new_y;
}

#ifnexists list_to_array
private define list_to_array (x)
{
   variable i, n = length (x);
   variable xx = Double_Type[n];
   _for i (0, n-1, 1)
     {
	xx[i] = x[i];
     }
   return xx;
}
#endif

define _xfig_clip_polygon2d (x, y, xmin, xmax, ymin, ymax)
{
   variable is_outside = (x < xmin);

   !if (any (is_outside or (x > xmax) or (y < ymin) or (y > ymax)))
     return (x, y);

   (x, y) = clip_1 (x, y, is_outside, &intersect_x, xmin);
   ifnot (length(y))
     {
	return Double_Type[0], Double_Type[0];
     }
   y = list_to_array (y);

   is_outside = (y < ymin);
   (x, y) = clip_1 (x, y, is_outside, &intersect_y, ymin);
   ifnot (length(x))
     {
	return Double_Type[0], Double_Type[0];
     }
   x = list_to_array (x);

   is_outside = (x > xmax);
   (x, y) = clip_1 (x, y, is_outside, &intersect_x, xmax);
   ifnot (length(y))
     {
	return Double_Type[0], Double_Type[0];
     }
   y = list_to_array (y);

   is_outside = (y > ymax);
   (x, y) = clip_1 (x, y, is_outside, &intersect_y, ymax);
   ifnot (length(x))
     {
	return Double_Type[0], Double_Type[0];
     }
   x = list_to_array (x);
   y = list_to_array (y);
   return x, y;
}

define xfig_clip_polygon2d (x, y, xmin, xmax, ymin, ymax)
{
   (x, y) = _xfig_clip_polygon2d (x, y, xmin, xmax, ymin, ymax);
   return xfig_new_polyline (vector(x,y,0*x));
}

