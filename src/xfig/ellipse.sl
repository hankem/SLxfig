private variable XFig_Ellipse_Type = struct
{
   object_code, % int (always 1)
     sub_type,			       % int (1: ellipse defined by radii  
				       % 2: ellipse defined by diameters  
				       % 3: circle defined by radius  
				       % 4: circle defined by diameter)  
     line_style, % int (enumeration type)
     thickness, % int (1/80 inch)
     pen_color, % int (enumeration type, pen color)
     fill_color, % int (enumeration type, fill color)
     depth, % int (enumeration type)
     pen_style, % int (pen style, not used)
     area_fill, % int (enumeration type, -1 = no fill)
     style_val, % float (1/80 inch)
     direction, % int (always 1)
     
     % These quantities describe the shape of the ellipse:
     %   angle, % float (radians, the angle of the x-axis)
     %   center_x, center_y, % int (Fig units)
     %   radius_x, radius_y, % int (Fig units)
     %   start_x, start_y, % int (Fig units; the 1st point entered)
     %   end_x, end_y, %int (Fig units; the last point entered)
     % They are represented below as 3 points that specify the center, major,
     % and minor axes
     X,
     next,
};
set_struct_fields (XFig_Ellipse_Type, 1, 1, 0, 1, -1, -1, 50, -1, -1, 1.0, 1);

private define make_ellipse (a, b)
{
   variable e = @XFig_Ellipse_Type;
   e.X = vector ([0,a,0], [0,0,b], [0,0,0]);
   return e;
}

private define render_ellipse (e, fp)
{
   variable x, y;
   (x,y) = xfig_project_to_xfig_plane (e.X);
   variable center_x = x[0];
   variable center_y = y[0];
   x -= center_x; y -= center_y;
   variable a_x = x[1], b_x = x[2], a_y = y[1], b_y = y[2];
   variable a = sqrt (a_x^2 + a_y^2);
   variable b = sqrt (b_x^2 + b_y^2);
   
   % Make a the major axis, and b the minor
   if (b > a)
     {
	(a, a_x, a_y, b, b_x, b_y) = (b, b_x, b_y, a, a_x, a_y);
     }

   if (a == 0)
     return;

   % Note the sign of the angle.  I may need to change this
   variable angle = -acos (a_x/a);

   if (b != 0)
     {
	variable cos_theta = (a_x*b_x+a_y*b_y)/(a*b);
	variable den = 1.0 - (b/a*cos_theta)^2;
	if (den != 0)
	  b *= sqrt ((1-cos_theta*cos_theta)/(den));
     }
   xfig_vwrite (fp, "%d %d %d %d %d %d %d %d %d %g %d ",
		e.object_code, e.sub_type, e.line_style, e.thickness,
		e.pen_color, e.fill_color, e.depth, e.pen_style, e.area_fill,
		e.style_val, e.direction);
   
   center_x = xfig_convert_units (center_x);
   center_y = xfig_convert_units (center_y);
   a = xfig_convert_units (a);
   b = xfig_convert_units (b);

   xfig_vwrite (fp, "%g %g %g %g %g %g %g %g %g\n",
		angle, center_x, center_y, a, b, center_x, center_y, a, b);
}



private define rotate_ellipse (e, axis, theta)
{
   e.X = vector_rotate (e.X, axis, theta);
}
private define translate_ellipse (e, dX)
{
   e.X = vector_sum (e.X, dX);
}
private define scale_ellipse (e, sx, sy, sz)
{
   variable X = e.X;
   X.x *= sx;
   X.y *= sy;
   X.z *= sz;
}

% FIXME:  This may be too simplistic
private define get_bbox_ellipse (e)
{
   variable X = e.X;
   return min(X.x), max(X.x), min(X.y), max(X.y), min(X.z), max(X.z);
}

private define set_depth (obj, depth)
{
   obj.depth = depth;
}


define xfig_new_ellipse (a, b)
{
   variable obj = xfig_new_object (make_ellipse (a,b));
   obj.render_fun = &render_ellipse;
   obj.set_depth = &set_depth;
   obj.rotate_fun = &rotate_ellipse;
   obj.translate_fun = &translate_ellipse;
   obj.scale_fun = &scale_ellipse;
   obj.get_bbox_fun = &get_bbox_ellipse;
   return obj;
}
   
   
   
   
