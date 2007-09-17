% -*- mode:slang; mode:fold -*-
% FIXME:
% It would be better to put the polyline stuff in a separate structure to
% produce something like:
%    { basic methods...
%      attribute_methods
%       { attributes }
%    }
% Then the polyline list would look like:
% 
%    { basic methods
%      attribute_methods
%      { attributes }
%      list ...
%    }
%  Polygon List would look like:
%  
%    { basic methods
%      }
%      
%
private variable Polyline_Type = struct
{
   X,				       %  vertices
   % Methods
   set_line_style, set_thickness, set_pen_color, set_fill_color, set_depth,
   set_area_fill, set_join_style, set_cap_style,

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
     backward_arrow % int (0: off, 1: on)
};

private variable SUBTYPE_POLYLINE	= 1;
private variable SUBTYPE_BOX		= 2;
private variable SUBTYPE_POLYGON	= 3;
private variable SUBTYPE_ARCBOX		= 4;
private variable SUBTYPE_IMPPICT	= 5;

private define set_line_style (obj, val)
{
   obj.line_style = val;
}

private define set_thickness (obj, val)
{
   obj.thickness = val;
}

private define set_pen_color (obj, val)
{
   if (typeof (val) == String_Type)
     val = xfig_lookup_color (val);
   obj.pen_color = val;
}

private define set_fill_color (obj, val)
{
   if (typeof (val) == String_Type)
     val = xfig_lookup_color (val);
   obj.fill_color = val;
}

private define set_depth (obj, val)
{
   obj.depth = val;
}

private define set_area_fill (obj, val)
{
   obj.area_fill = val;
}

private define set_join_style (obj, val)
{
   obj.join_style = val;
}

private define set_cap_style (obj, val)
{
   obj.cap_style = val;
}


Polyline_Type.set_line_style = &set_line_style;
Polyline_Type.set_thickness = &set_thickness;
Polyline_Type.set_pen_color = &set_pen_color;
Polyline_Type.set_fill_color = &set_fill_color;
Polyline_Type.set_depth = &set_depth;
Polyline_Type.set_area_fill = &set_area_fill;
Polyline_Type.set_join_style = &set_join_style;
Polyline_Type.set_cap_style = &set_cap_style;
  
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

private define write_one_polyline (fp, p, X)
{
   variable x, y;
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

private define polyline_render_to_fp (p, fp)
{
   write_one_polyline (fp, p, p.X);
}

private define polyline_rotate (obj, axis, theta)
{
   obj.X = vector_rotate (obj.X, axis, theta);
}

private define polyline_translate (obj, dX)
{
   obj.X = vector_sum (obj.X, dX);
}

private define polyline_scale (obj, sx, sy, sz)
{
   variable X = obj.X;
   X.x *= sx;
   X.y *= sy;
   X.z *= sz;
   obj.X = X;
}

private define polyline_get_bbox (obj)
{
   variable X = obj.X;
   return min(X.x), max(X.x), min(X.y), max(X.y), min(X.z), max(X.z);
}

define xfig_new_polyline (X)
{
   variable p = @Polyline_Type;
   p.object_code = SUBTYPE_POLYLINE;
   p.X = X;

   variable obj = xfig_new_object (p);
   obj.render_to_fp = &polyline_render_to_fp;
   obj.rotate = &polyline_rotate;
   obj.translate = &polyline_translate;
   obj.scale = &polyline_scale;
   obj.get_bbox = &polyline_get_bbox;
   return obj;
}

%------------------------------------------------------------------------
% Polyline_List
% 
% All objects in the polyline list have the same attributes.
%------------------------------------------------------------------------
%{{{

private define polyline_list_render_to_fp (p, fp)
{
   foreach (p.list)
     {
	variable X = ();
	write_one_polyline (fp, p, X);
     }
}

private define polyline_list_rotate (obj, axis, theta)
{
   variable list = obj.list;
   _for (0, length(list)-1, 1)
     {
	variable i = ();
	list[i] = vector_rotate (list[i], axis, theta);
     }
}

private define polyline_list_translate (obj, dX)
{
   variable list = obj.list;
   _for (0, length(list)-1, 1)
     {
	variable i = ();
	list[i] = vector_sum (list[i], dX);
     }
}

private define polyline_list_scale (obj, sx, sy, sz)
{
   variable list = obj.list;
   _for (0, length(list)-1, 1)
     {
	variable i = ();
	variable X = list[i];
	X.x *= sx;
	X.y *= sy;
	X.z *= sz;
	list[i] = X;
     }
}

private define polyline_list_get_bbox (obj)
{
   variable x0, x1, y0, y1, z0, z1;
   variable xmin = _Inf, ymin = _Inf, zmin = _Inf;
   variable xmax = -_Inf, ymax = -_Inf, zmax = -_Inf;
   foreach (obj.list)
     {
	variable X = ();
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

private define polyline_list_insert (p, X)
{
   list_insert (p.list, X);
}

define xfig_new_polyline_list ()
{
   variable p = xfig_new_polyline (vector(0,0,0));
   
   p = struct_combine (p, "insert", "list");
   p.list = {};
   p.insert = &polyline_list_insert;

   p.render_to_fp = &polyline_list_render_to_fp;
   p.rotate = &polyline_list_rotate;
   p.translate = &polyline_list_translate;
   p.scale = &polyline_list_scale;
   p.get_bbox = &polyline_list_get_bbox;
   return p;
}

%}}}

%------------------------------------------------------------------------
% Polygon_Type
%
%------------------------------------------------------------------------
%{{{
private define polygon_render_to_fp (obj, fp)
{
   variable eye = xfig_get_eye ();
   variable n = obj.n;
   variable X = obj.X;
   variable dX = vector_diff (eye, vector(X.x[0],X.y[0],X.z[0]));
   if (dotprod (dX, n) < 0)
     return;
   write_one_polyline (fp, obj, X);
}

define xfig_new_polygon (X)
{
   variable p = xfig_new_polyline (X);
   p = struct_combine (p, "n");
   p.object_code = SUBTYPE_POLYGON;
   variable x = X.x, y = X.y, z = X.z;
   variable x0 = vector (x[0], y[0], z[0]);
   variable x1 = vector (x[1], y[1], z[1]);
   variable x2 = vector (x[2], y[2], z[2]);
   p.n = crossprod (vector_diff (x1, x0), vector_diff (x2, x1));
   normalize_vector (p.n);
   return p;
}


%}}}

%------------------------------------------------------------------------
% Polygon_List 
% 
% A Polygon_List_Type consists of a linked list of (closed) polygons.
% When rendered, it properly takes into account the position of the polygons 
% with respect to the viewer.
%
% If drawing 3d objects, then use polygons and not polylines.
%------------------------------------------------------------------------
%{{{
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

private define sort_polygons (list)
{
   variable count = length (list);
   variable ps = Struct_Type[count];
   variable i;
   _for (0, count-1, 1)
     {
	i = ();
	ps[i] = list[i];
     }
   return ps[array_sort (ps, &poly_sort)];
}

private define polygon_list_render_to_fp (obj, fp)
{
   variable ps = sort_polygons (obj.list);
   variable eye = xfig_get_eye ();
   foreach (ps)
     {
	variable p = ();
	variable n = p.n;
	variable X = p.X;
	variable dX = vector_diff (eye, vector(X.x[0],X.y[0],X.z[0]));
	if (dotprod (dX, n) < 0)
	  continue;
	write_one_polyline (fp, p, p.X);
     }
}

private define polygon_list_set_line_style (obj, val)
{
   foreach (obj.list)
     {
	obj = ();
	obj.line_style = val;
     }
}

private define polygon_list_set_thickness (obj, val)
{
   foreach (obj.list)
     {
	obj = ();
	obj.thickness = val;
     }
}

private define polygon_list_set_pen_color (obj, val)
{
   if (typeof (val) == String_Type)
     val = xfig_lookup_color (val);
   foreach (obj.list)
     {
	obj = ();
	obj.pen_color = val;
     }
}

private define polygon_list_set_fill_color (obj, val)
{
   if (typeof (val) == String_Type)
     val = xfig_lookup_color (val);
   foreach (obj.list)
     {
	obj = ();
	obj.fill_color = val;
     }
}

private define polygon_list_set_area_fill (obj, val)
{
   foreach (obj.list)
     {
	obj = ();
	obj.area_fill = val;
     }
}

define xfig_new_polygon_list ()
{
   variable list = xfig_new_compound_list ();
   list = struct_combine (list, 
			  "set_line_style", "set_thickness", "set_pen_color",
			  "set_fill_color", "set_area_fill");
   list.set_line_style = &polygon_list_set_line_style;
   list.set_thickness = &polygon_list_set_thickness;
   list.set_pen_color = &polygon_list_set_pen_color;
   list.set_fill_color = &polygon_list_set_fill_color;
   list.set_area_fill = &polygon_list_set_area_fill;
   list.render_to_fp = &polygon_list_render_to_fp;
   return list;
}


%}}}

%-----------------------------------------------------------------------
% Pict_Type
%
%-----------------------------------------------------------------------
%{{{
private define pict_render_to_fp (p, fp)
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

define pict_rotate_pict (pict, theta_degrees)
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
%\synopsis{}
%\usage{xfig_scale_pict (pict, sx [,sy])}
%\description
%\example
%\notes
%\seealso{}
%!%-
private define pict_scale_pict ()
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
   
   pict.bbox_x *= sx;
   pict.bbox_y *= sy;
}

% FIXME: This does not look right
define pict_get_pict_bbox (pict)
{
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
private define pict_center_pict (pict, X, dx, dy)
{
   variable w, h;
   (w, h) = pict_get_pict_bbox (pict);
   variable yoff = 0.5*(dy - h);
   if (yoff < 0)
     yoff = 0.0*dy;
   variable xoff = 0.5*(dx - w);
   if (xoff < 0)
     xoff = 0.0*dx;		       %  used to be 0.1*dx
   pict_translate (pict, vector_sum(X, vector (xoff, yoff, 0)));
}

define xfig_new_pict (file, dx, dy)
{
   variable p = xfig_new_polyline (vector (0,0,0));
   p.sub_type = SUBTYPE_IMPPICT;

   p = struct_combine (p, "pict_file", "flipped", "bbox_x", 
		       "bbox_y", "rotate_pict", "scale_pict", "get_pict_bbox",
		       "center_pict");

   % Use the corners for the polyline
   p.flipped = 0;
   if (dy < 0)
     {
	p.flipped = 1;
	dy = -dy;
     }
   p.bbox_x = [0, dx, dx, 0, 0];
   p.bbox_y = [0, 0, dy, dy, 0];
   p.pict_file = file;
   p.rotate_pict = &pict_rotate_pict;
   p.scale_pict = &pict_scale_pict;
   p.get_pict_bbox = &pict_get_pict_bbox;
   p.center_pict = &pict_center_pict;

   p.render_to_fp = &pict_render_to_fp;
   p.scale = &pict_scale;
   p.rotate = &pict_rotate;
   p.get_bbox = &pict_get_bbox;
   return p;
}

%}}}

define xfig_new_pyramid (n, radius, height)
{
   variable a = xfig_new_polygon_list ();
   
   variable thetas = [n:0:-1]*(2*PI)/n;

   variable xs = radius * cos (thetas);
   variable ys = radius * sin (thetas);

   % base
   variable X = vector (xs, ys, Double_Type[n+1]);
   a.insert (xfig_new_polygon (X));
   
   _for (0, n-1, 1)
     {
	variable i = ();
	variable j = i+1;
	X = vector ([xs[i], 0, xs[j], xs[i]],
		    [ys[i], 0, ys[j], ys[i]],
		    [0, height, 0, 0]);
	a.insert (xfig_new_polygon (X));
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
	a.rotate (axis, theta);
     }
   a.set_area_fill (20);
   a.set_fill_color ("default");
   return a;
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
