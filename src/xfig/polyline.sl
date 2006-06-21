_debug_info =1;

private variable Polyline_Type = struct
{
   object_code,  % int (always 2)
     sub_type, % (1: polyline, 2: box, 3: polygon, 4: arc-box, 5: imported-picture bounding-box)
     line_style, % int (enumeration type)
     thickness, % int (1/80 inch)
     pen_color, % int (enumeration type, pen color)
     fill_color, % int (enumeration type, fill color)
     depth, % int (enumeration type)
     pen_style, % int (pen style, not used)
     area_fill, % int (enumeration type, -1 = no fill)
     style_val, % float (1/80 inch) of  on/off dashes, etc...
     join_style, % int (enumeration type)
     cap_style, % int (enumeration type, only used for POLYLINE)
     radius, % int (1/80 inch, radius of arc-boxes)
     forward_arrow, % 
     backward_arrow, % int (0: off, 1: on)
     X,				       %  vector
     n,				       %  outward normal, used for sorting
     pict_file, flipped, bbox_x, bbox_y,
     next			       %  next in list
};

private variable SUBTYPE_POLYLINE	= 1;
private variable SUBTYPE_BOX		= 2;
private variable SUBTYPE_POLYGON		= 3;
private variable SUBTYPE_ARCBOX		= 4;
private variable SUBTYPE_IMPPICT		= 5;

Polyline_Type.object_code = SUBTYPE_POLYLINE;
Polyline_Type.sub_type = 1;
Polyline_Type.line_style = 0;
Polyline_Type.thickness = 1;
Polyline_Type.pen_color = 0;
Polyline_Type.fill_color = 0;
Polyline_Type.depth = 50;
Polyline_Type.pen_style = 0;
Polyline_Type.area_fill = -1;
Polyline_Type.style_val = 4.0;
Polyline_Type.join_style = 1;
Polyline_Type.cap_style = 0;
Polyline_Type.radius = 10;
Polyline_Type.forward_arrow = NULL;
Polyline_Type.backward_arrow = NULL;

private define write_arrow (fp, a, X, i1, i2)
{
   variable X1, X2;
   X1 = vector (X.x[i1], X.y[i1], X.z[i1]);
   X2 = vector (X.x[i2], X.y[i2], X.z[i2]);
   variable dX = vector_diff (X2,X1);
   normalize_vector (dX);
   variable x1, x2, y1, y2, width, height;
   width = a.arrow_width;
   height = a.arrow_height;

   (x1,y1) = xfig_project_to_xfig_plane (X2);
   (x2,y2) = xfig_project_to_xfig_plane (vector_sum (X2, vector_mul(height, dX)));
   height = sqrt ((x2-x1)^2+(y2-y1)^2);

   % Now make a vector normal to dX to project the width.   This one will work
   % for this purpose
   dX = vector (-dX.y, dX.x, 0);
   normalize_vector (dX);
   (x2,y2) = xfig_project_to_xfig_plane (vector_sum (X2, vector_mul(width, dX)));
   width = sqrt ((x2-x1)^2+(y2-y1)^2);
   
   width = xfig_convert_units (width);
   height = xfig_convert_units (height);
   xfig_vwrite (fp, " %d %d %g %g %g\n", 
		a.arrow_type, a.arrow_style, a.arrow_thickness, 
		width, height);
}

private define write_polyline_header (fp, p, n)
{
   xfig_vwrite (fp, "%d %d %d %d %d %d %d %d %d %g %d %d %d %d %d %d\n",
		2, p.sub_type, p.line_style, p.thickness, p.pen_color,
		p.fill_color, p.depth, p.pen_style, p.area_fill, p.style_val,
		p.join_style, p.cap_style, p.radius, 
		(p.forward_arrow != NULL), (p.backward_arrow != NULL), n);
}

private define write_polyline_data (fp, x, y)
{
   _for (0, length(x)-1, 1)
     {
	variable i = ();
	xfig_vwrite (fp, " %d %d", x[i], y[i]);
     }
   xfig_write (fp, "\n");
}

private define prune(x,y)
{
   variable dx = (x!=shift(x,-1));
   variable dy = (y!=shift(y,-1));
   dx[0]=1;
   variable i = where (dx or dy);
   if (length (i) != length(x))
     return x[i], y[i];
   return x, y;
}
private define write_one_polygon (fp, p)
{
   variable x, y;
   variable X = p.X;
   variable n;

   (x,y) = xfig_project_to_xfig_plane (X);
   n = length (x);
   if (n < 2)
     return;

   x = xfig_convert_units (__tmp(x));
   y = xfig_convert_units (__tmp(y));

#iftrue
   (x,y) = prune (__tmp(x), __tmp(y));
   n = length (x);
   if (n < 2) return;
#endif

   write_polyline_header (fp, p, n);

   if (p.forward_arrow != NULL)
     write_arrow (fp, p.forward_arrow, X, -2, -1);
   
   if (p.backward_arrow != NULL)
     write_arrow (fp, p.backward_arrow, X, 1, 0);

   write_polyline_data (fp, x, y);
}

private define poly_sort (a, b)
{
   variable za, zb;
   za = max (a.X.z);
   zb = max (b.X.z);
   if (za > zb) return +1;
   if (za < zb) return -1;
   variable na = a.n;
   variable nb = b.n;
   if (na == NULL)
     {
	if (nb != NULL)
	  return 1;
     }
   else if (nb == NULL)
     return -1;

   % Using the length has the feature that a single line will get drawn
   % after something more complex.
   return (length (a.X) < length (b.X));
}

private define sort_polylines (p)
{
   variable count = 0;
   variable q = p;
   
   while (q != NULL)
     {
	count++;
	q = q.next;
     }
   variable ps = Struct_Type[count];
   count = 0;
   q = p;
   while (q != NULL)
     {
	ps[count] = q;
	count++;
	q = q.next;
     }
   
   variable i = array_sort (ps, &poly_sort);
   ps = ps[i];
   return ps;
}

define xfig_make_polygon (X)
{
   variable p = @Polyline_Type;
   p.sub_type = SUBTYPE_POLYGON;
   p.X = X;
   variable x = X.x, y = X.y, z = X.z;
   variable x0 = vector (x[0], y[0], z[0]);
   variable x1 = vector (x[1], y[1], z[1]);
   variable x2 = vector (x[2], y[2], z[2]);
   p.n = crossprod (vector_diff (x1, x0), vector_diff (x2, x1));
   normalize_vector (p.n);
   return p;
}

define xfig_make_polyline (X)
{
   variable p = @Polyline_Type;
   p.sub_type = SUBTYPE_POLYLINE;
   p.X = X;
   p.n = NULL;
   return p;
}


  
define xfig_polyline_add_forward_arrow (p, a)
{
   p.forward_arrow = a;
}

define xfig_polyline_add_backward_arrow (p, a)
{
   p.backward_arrow = a;
}

% A Polyline_List is a compound object consisting only of polylines.  When
% rendered, it properly takes into account the position of the polygons with
% respect to the viewer.
private variable Polyline_List_Type = struct
{
   polyline_list,
};

define xfig_polyline_list_insert (obj, p)
{
   variable list = obj.object;
   p.next = list.polyline_list;
   list.polyline_list = p;
}
 
private define render_polyline_list (list, fp)
{
   variable ps = sort_polylines (list.polyline_list);
   variable eye = xfig_get_eye ();
   foreach (ps)
     {
	variable p = ();
	variable n = p.n;
	variable X = p.X;
	if (n != NULL)
	  {
	     variable dX = vector_diff (eye, vector(X.x[0],X.y[0],X.z[0]));
	     if (dotprod (dX, n) < 0)
	       continue;
	  }
	write_one_polygon (fp, p);
     }
}

private define polyline_list_rotate (list, axis, theta)
{
   foreach (list.polyline_list) using ("next")
     {
	variable p = ();
	p.X = vector_rotate (p.X, axis, theta);
	if (p.n != NULL)
	  p.n = vector_rotate (p.n, axis, theta);
     }
}

private define polyline_list_translate (list, dX)
{
   foreach (list.polyline_list) using ("next")
     {
	variable p = ();
	p.X = vector_sum (p.X, dX);
     }
}

private define polyline_list_scale (list, sx, sy, sz)
{
   foreach (list.polyline_list) using ("next")
     {
	variable p = ();
	variable X = p.X;
	X.x *= sx;
	X.y *= sy;
	X.z *= sz;
     }
}

private define polyline_set_attr (list, attr, val)
{
   foreach (list.polyline_list) using ("next")
     {
	variable p = ();
	xfig_primative_set_attr (p, attr, val);
     }   
}

private variable Infinity = 1e38;
private define polyline_list_get_bbox (list)
{
   variable x0, x1, y0, y1, z0, z1;
   variable xmin = Infinity, ymin = Infinity, zmin = Infinity;
   variable xmax = -Infinity, ymax = -Infinity, zmax = -Infinity;
   foreach (list.polyline_list) using ("next")
     {
	variable p = ();
	variable X = p.X;
	if (length (X.x) == 0)
	  continue;
	x0 = min (X.x);
	if (x0 < xmin) xmin = x0;
	x1 = max (X.x);
	if (x1 > xmax) xmax = x1;
	y0 = min (X.y);
	if (y0 < ymin) ymin = y0;
	y1 = max (X.y);
	if (y1 > ymax) ymax = y1;
	z0 = min (X.z);
	if (z0 < zmin) zmin = z0;
	z1 = max (X.z);
	if (z1 > zmax) zmax = z1;
     }
   
   return xmin, xmax, ymin, ymax, zmin, zmax;
}

define xfig_new_polyline_list ()
{
   variable p = @Polyline_List_Type;
   variable obj = xfig_new_object (p);
   obj.render_fun = &render_polyline_list;
   obj.rotate_fun = &polyline_list_rotate;
   obj.translate_fun = &polyline_list_translate;
   obj.scale_fun = &polyline_list_scale;
   obj.set_attr_fun = &polyline_set_attr;
   obj.get_bbox_fun = &polyline_list_get_bbox;
   return obj;
}


private variable XFig_Arrow_Type = struct
{
   arrow_type, % int (enumeration type)
     arrow_style, % int (enumeration type)
     arrow_thickness, % float (1/80 inch)
     arrow_width, % float (Fig units)
     arrow_height, % float (Fig units)
};

define xfig_create_arrow ()
{
   variable a = @XFig_Arrow_Type;
   a.arrow_type = 2;
   a.arrow_style = 3;
   a.arrow_thickness = 1;
   a.arrow_width = (1.0/80.0)*4 * 2.54;
   a.arrow_height = (1.0/80.0)*8 * 2.54;
   return a;
}

private define pict_render (p, fp)
{
   variable flipped = 0;
   variable x0, y0, x1, y1, x, y;

   (x0,y0) = xfig_project_to_xfig_plane (p.X);

   % This point must correspond to the lower left corner of the picture
   % or, in fig units the corner with the smallest x and the largest y.
   variable bbox_x = p.bbox_x + (x0 - 0.5*max(p.bbox_x));
   variable bbox_y = p.bbox_y;
   bbox_y = bbox_y + (y0 - 0.5*max(bbox_y));

   bbox_x = xfig_convert_units (bbox_x);
   bbox_y = xfig_convert_units (bbox_y);

   write_polyline_header (fp, p, 5);
   xfig_vwrite (fp, " %d %s\n", p.flipped, p.pict_file);
   write_polyline_data (fp, bbox_x, bbox_y);
}

private define pict_get_bbox (p)
{
   variable X = p.X;
   variable dx, dy, dz, x, y, z;
   dx = 0.5*max(abs(p.bbox_x));
   dy = 0.5*max(abs(p.bbox_y));
   dz = 0.0;
   x = X.x; y = X.y; z = X.z;
   return x-dx, x+dx, y-dy, y+dy, z, z+dz;
}

private define pict_scale (p, sx, sy, sz)
{
   variable pict = p.polyline_list;
   pict.bbox_x *= sx;
   pict.bbox_y *= sy;
   polyline_list_scale (p, sx, sy, sz);
}

private define pict_rotate (p, axis, theta)
{
   p.X = vector_rotate (p.X, axis, theta);
}

private define pict_translate (p, dX)
{
   p.X += dX;
}

define xfig_new_pict (file, dx, dy)
{
   variable p = @Polyline_Type;
   variable obj = xfig_new_object (p);
   p.sub_type = SUBTYPE_IMPPICT;

   % Use the corners for the polyline
   p.flipped = 0;
   if (dy < 0)
     {
	p.flipped = 1;
	dy = -dy;
     }
   p.bbox_x = [0, dx, dx, 0, 0];
   p.bbox_y = [0, 0, dy, dy, 0];

   p.X = vector (0, 0, 0);
   p.pict_file = file;

   obj.render_fun = &pict_render;
   obj.scale_fun = &pict_scale;
   obj.rotate_fun = &pict_rotate;
   obj.translate_fun = &pict_translate;
   %obj.set_attr_fun = &pict_set_attr;
   obj.get_bbox_fun = &pict_get_bbox;
   return obj;
}

private define pict_from_object (pict)
{
   return pict.object;
}

define xfig_rotate_pict (obj, theta_degrees)
{
   % The convention adopted here is that the location of the picture is
   % specified by the lower left corner of the box, rotated or
   % otherwise.  In fig units, this corner will have the largest y
   % value and smallest x value (UL in diagram below, displayed in fig
   % system):
   %
   % 	      UL UR
   % 	      LL LR
   %
   % The rotation of the figure itself is encoded by how the box is
   % written out:
   %
   %     0 degrees:  LL LR UR UL LL   (dx>0, dy>0)
   %    90 degrees:  LR UR UL LL LR   (dx<0, dy>0)
   %   180 degrees:  UR UL LL LR UR   (dx<0, dy<0)
   %   270 degrees:  UL LL LR UR UL   (dx>0, dy<0)
   variable pict = pict_from_object (obj);
   variable bbox_x = pict.bbox_x;
   variable bbox_y = pict.bbox_y;
   theta_degrees = theta_degrees mod 360.0;
   if (theta_degrees < 0) theta_degrees += 360;
   variable n = int(theta_degrees / 90.0 + 0.5);
   
   loop (n)
     {
	bbox_x[[0:3]] = bbox_x[[1:4]];  bbox_x[4] = bbox_x[0];
	bbox_y[[0:3]] = bbox_y[[1:4]];  bbox_y[4] = bbox_y[0];
	(bbox_x, bbox_y) = (bbox_y, bbox_x);
     }
   pict.bbox_x = bbox_x;
   pict.bbox_y = bbox_y;
}


%!%+
%\function{xfig_scale_pict}
%\synopsis{Scale a pict object}
%\usage{xfig_scale_pict (pict, sx [,sy])}
%!%-
define xfig_scale_pict ()
{
   variable pict, sx, sy;
   if (_NARGS == 2)
     {
	(pict, sx) = ();
	sy = sx;
     }
   else
     {
	(pict, sx, sy) = ();
     }
   
   pict = pict_from_object (pict);
   pict.bbox_x *= sx;
   pict.bbox_y *= sy;
}

% FIXME: This does not look right
define xfig_get_pict_bbox (pict)
{
   pict = pict_from_object (pict);
   return max(abs(pict.bbox_x)), max(abs(pict.bbox_y));
}

%!%+
%\function{xfig_center_pict_in_box}
%\synopsis{Center a pict object in a box}
%\usage{xfig_center_pict_in_box (pict_object, X, dx, dy}
%\description
% This function takes a pict object and centers it in a box whose width
% is \var{dx} and whose height is \var{dy}.  The vector \var{X} denotes the
% position of the lower-left corner of the box.  If the pict object is too 
% big to fit in the box, then its lower-left corner will coincide with the 
% lower-left corner of the box.
%\seealso{xfig_translate_object}
%!%-
define xfig_center_pict_in_box (label, X, dx, dy)
{
   variable w, h;
   (w, h) = xfig_get_pict_bbox (label);
   variable yoff = 0.5*(dy - h);
   if (yoff < 0)
     yoff = 0.0*dy;
   variable xoff = 0.5*(dx - w);
   if (xoff < 0)
     xoff = 0.0*dx;		       %  used to be 0.1*dx
   xfig_translate_object (label, vector_sum(X, vector (xoff, yoff, 0)));
}

private define create_pyramid (width, height)
{
   variable a = xfig_new_polyline_list ();
   width *= 0.5;
   
   % bottom
   variable X = vector ([-width, -width, width, width, -width],
			[-width, width, width, -width, -width],
			[0, 0, 0, 0, 0]);
   xfig_polyline_list_insert (a, xfig_make_polygon (X));
   
   %left
   X = vector([-width, width, 0, width],
	      [-width, -width, 0, -width],
	      [0, 0, height, 0]);
   xfig_polyline_list_insert (a, xfig_make_polygon (X));
   
   %front 
   X = vector([width, width, 0, width],
	      [-width, width, 0, -width],
	      [0, 0, height, 0]);
   xfig_polyline_list_insert (a, xfig_make_polygon (X));
   
   % right
   X = vector([-width, 0, width, -width],
	      [width, 0, width, width],
	      [0, height, 0, 0]);
   xfig_polyline_list_insert (a, xfig_make_polygon (X));
   
   % back
   X = vector([-width, 0, -width, -width],
	      [-width, 0, width, -width],
	      [0, height, 0, 0]);
   xfig_polyline_list_insert (a, xfig_make_polygon (X));

   return a;
}

define xfig_new_pyramid (n, radius, height)
{
   variable a = xfig_new_polyline_list ();
   
   variable thetas = [n:0:-1]*(2*PI)/n;

   variable xs = radius * cos (thetas);
   variable ys = radius * sin (thetas);

   % base
   variable X = vector (xs, ys, Double_Type[n+1]);
   xfig_polyline_list_insert (a, xfig_make_polygon (X));
   
   _for (0, n-1, 1)
     {
	variable i = ();
	variable j = i+1;
	X = vector ([xs[i], 0, xs[j], xs[i]],
		    [ys[i], 0, ys[j], ys[i]],
		    [0, height, 0, 0]);
	xfig_polyline_list_insert (a, xfig_make_polygon (X));
     }
   return a;
}

define xfig_new_arrow_head (w, h, dX)
{
   dX = @dX;
   normalize_vector (dX);
   variable a = xfig_new_pyramid (6, w*0.5, h);
   variable theta = acos (dX.z);
   if (theta != 0.0)
     {
	variable axis = unit_vector (crossprod (vector (0,0,1), dX));
	xfig_rotate_object (a, axis, theta);
     }
   xfig_set_area_fill (a, 20);
   xfig_set_fill_color (a, "default");
   return a;
}

define xfig_new_polygon (X)
{
   variable obj = xfig_new_polyline_list ();
   xfig_polyline_list_insert (obj, xfig_make_polygon (X));
   return obj;
}

define xfig_new_polyline (X)
{
   variable obj = xfig_new_polyline_list ();
   xfig_polyline_list_insert (obj, xfig_make_polyline (X));
   return obj;
}
