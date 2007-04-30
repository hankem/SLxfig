private variable DEFAULT_IMAGE_DEPTH = 89;
private variable DEFAULT_LINE_DEPTH = DEFAULT_IMAGE_DEPTH-10;
private variable DEFAULT_POINT_DEPTH = DEFAULT_LINE_DEPTH-10;
private variable DEFAULT_AXIS_DEPTH = DEFAULT_POINT_DEPTH-10;

private variable ERRBAR_TERMINAL_SIZE = 0.1;

#iffalse
define xfig_new_plot2d_axes (dx, dy, xlabel, ylabel)
{
   variable xaxis = xfig_new_polyline_with_arrow (vector ([0,dx], [0,0],[0,0]), 0.2, 0.4);
   variable yaxis = xfig_new_polyline_with_arrow (vector ([0,0], [0,dy],[0,0]), 0.2, 0.4);
   variable w, h, x, y;
   if (xlabel != NULL)
     {
	xlabel = xfig_new_text (xlabel);
	(w, h) = xfig_get_pict_bbox (xlabel);
	x = 0.5*(dx - w);
	if (x < 0)
	  x = 0.1*dx;
	xfig_translate_object (xlabel, vector (x, -1.1*h, 0));
     }

   if (xlabel != NULL)
     {
	ylabel = xfig_new_text (ylabel);
	xfig_rotate_pict (ylabel, 90);
	(w, h) = xfig_get_pict_bbox (ylabel);
	y = 0.5*(dy - h);
	if (y < 0)
	  y = 0.1*dy;
	x = -1.1*w;
	xfig_translate_object (ylabel, vector (x, y, 0));
     }
   
   return xfig_new_compound (xaxis, yaxis, xlabel, ylabel);
}
#endif
private define convert_to_array (s, n)
{
   variable type = typeof (s);
   if (type == Array_Type)
     return s;
   
   variable a = (@Array_Type)(type, [n]);
   a[*] = s;
   return a;
}

   
%!%+
%\function{xfig_new_legend}
%\synopsis{Create a plot legend object}
%\usage{legend = xfig_new_legend (labels[], colors[], linestyles[], thicknesses[], width}
%\description
% The \var{xfig_new_legend} function creates a legend object suitable for adding
% to a plot.  The legend will consist of ...
%!%-
% FIXME: allow any object, not just a line...
define xfig_new_legend (labels, colors, linestyles, 
			       thicknesses, width)
{
   variable num = length(labels);
   colors = convert_to_array (colors, num);
   linestyles = convert_to_array (linestyles, num);
   thicknesses = convert_to_array (thicknesses, num);

   variable legend = xfig_new_compound_list ();

   variable height = 0;
   variable x = width + 0.2;
   variable x0, x1, y0, y1;
   variable y = 0;
   _for (0, num-1, 1)
     {
	variable i = ();
	
	variable obj = xfig_new_text (labels[i]);
	xfig_justify_object (obj, vector (x,y,0), vector (-0.5, 0.5, 0));
	xfig_compound_list_insert (legend, obj);

	(,,y0,y1,,) = xfig_get_object_bbox (obj);
	y = 0.5*(y0+y1);
	obj = xfig_new_polyline (vector([0,width], [y,y], [0,0]));
	xfig_set_pen_color (obj, colors[i]);
	xfig_set_thickness (obj, thicknesses[i]);
	xfig_set_line_style (obj, linestyles[i]);
	xfig_compound_list_insert (legend, obj);

	y = y0 - 0.1 * (y1-y0);
     }
   
   (x0, x1, y0, y1,,) = xfig_get_object_bbox (legend);
   variable border = (0.5 * (y1-y0))/num;
   xfig_translate_object (legend, vector (border-x0, border-y0, 0));
   variable box = xfig_new_rectangle ((x1-x0)+2*border, (y1-y0)+2*border);
   xfig_compound_list_insert (legend, box);
   return legend;
}


private define compute_major_tics (xmin, xmax, maxtics, tic_intervals)
{
   variable diff = xmax - xmin;
   variable multiplier = 1.0;
   variable factor = 10.0;
   variable last_diff;
   variable max_diff = tic_intervals[-1]*maxtics;

   while (diff <= max_diff)
     {
	multiplier *= factor;
	last_diff = diff;
	diff *= factor;
	if (last_diff == diff)
	  return [xmin,xmax], 0;
     }
   while (diff > max_diff)
     {
	multiplier *= 1.0/factor;
	last_diff = diff;
	diff *= 1.0/factor;
	if (last_diff == diff)
	  return [xmin,xmax], 0;
     }

   variable tic_interval;
   variable nth_chosen = 0;
   foreach (tic_intervals)
     {
	tic_interval = ();
	if (diff/tic_interval <= maxtics)
	  break;
	nth_chosen++;
     }

   tic_interval /= multiplier;
   variable nmin = xmin / tic_interval;
   if (abs(nmin) > 0x7FFFFFFF)
     return [xmin,xmax];
   nmin = int(nmin);
   if (xmin < 0)
     nmin--;

   variable nmax = xmax/tic_interval;
   if (abs(nmin) > 0x7FFFFFFE)
     return [xmin,xmax];
   nmax = int(nmax);
   if (xmax > 0)
     nmax++;

   tic_intervals = [nmin:nmax]*tic_interval;
   return tic_intervals, nth_chosen;
}

define get_major_tics (xmin, xmax, islog, maxtics)
{
   variable tic_intervals = [1.0,2.0,5.0];
   variable num_minor = [4, 1, 4];

   if (islog)
     {
	xmin = log10(xmin);
	xmax = log10(xmax);
	if (xmin < 0)
	  xmin -= 1.0;
	xmin = int(xmin);

	if (xmax > 0)
	  xmax += 1.0;
	xmax = int(xmax);
	tic_intervals = [1];
	maxtics = (xmax - xmin + 1);
	
	variable tics = compute_major_tics (xmin, xmax, maxtics, tic_intervals);
	return tics [where (tics == int(tics))];
     }
   variable ti, n;
   
   (ti, n) = compute_major_tics (xmin, xmax, maxtics, tic_intervals);
   return ti, num_minor[n];
}

% A "Plot" consists of a plotting area surrounded by a box, with optional tic
% marks and labels:
% 
%                            X2 axis label
%                            X2 tic labels
%                   +-----+-----+-----+-----+-----+-----+
%                y1 +                                   + y2
%   Y1-label    tic +                                   + tic      Y2 label
%            labels +                                   + labels
%                   +-----+-----+-----+-----+-----+-----+
%                            X1 tic labels
%                            X1 axis label
%
%
% The X1 axis label is placed below the X axis by an amount depending upon the
% size of the X1 tic labels.  Similar considerations apply to the other axes.
% The Y1/Y2 labels will be rotated 90 degrees
% 
private variable Plot_Axis_Type = struct
{
   X, dX, dY,			       %  position of axis, direction, tic dir
   xmin, xmax, islog, wcs_transform,
     major_tics, minor_tics, maxtics, 
     %tic_label_format, tic_labels, tic_labels_dX,   %  from tic
     tic_label_format, tic_labels, 
     tic_labels_tweak, % from tic
     tic_labels_just,    % justification
     max_tic_h, max_tic_w,	       % max width and height of tic label bbox
     line, major_tic_marks, minor_tic_marks,
     axis_label,
     
     color, line_style, thickness, depth,

};

private variable XFig_Plot_Legend_Type = struct
{
   X, width,
   names, objects
};

private variable XFig_Plot_Type = struct
{
     X,
     plot_width, plot_height,	       %  plot window, does not include labels
     x1axis, y1axis, x2axis, y2axis,   %  Plot_Axis_Type
     line_color, line_style, thickness, 
     point_color, point_size,
     object_list, title,
     line_depth, point_depth, axis_depth, image_depth,
     legend
};


private variable WCS_Transforms = Assoc_Type[];
private define setup_axis_wcs (axis, wcs_type)
{
   if (0 == assoc_key_exists (WCS_Transforms, wcs_type))
     {
	vmessage ("*** Warning: axis transform %s not supported.  Using linear");
	wcs_type = "linear";
     }
   axis.islog = (wcs_type == "log");
   axis.wcs_transform = WCS_Transforms[wcs_type];
}

define xfig_plot_add_transform (name, world_to_normalized, normalized_to_world)
{
   variable s = struct
     {
	world_to_normalized, normalized_to_world,
     };
   s.world_to_normalized = world_to_normalized;
   s.normalized_to_world = normalized_to_world;
   WCS_Transforms[name] = s;
}

private define linear_world_to_normalized (x, xmin, xmax)
{
   return (x-xmin)/(xmax-xmin);
}

private define linear_normalized_to_world (t, xmin, xmax)
{
   return xmin + t * (xmax - xmin);
}
xfig_plot_add_transform ("linear", &linear_world_to_normalized, &linear_normalized_to_world);

private define check_xmin_xmax_for_log (xmin, xmax)
{
   variable tweaked = 0;
   if (xmax <= 0.0)
     {
	xmax = 1.0;
	tweaked++;
     }
   if (xmin <= 0.0)
     {
	tweaked++;
	xmin = 0.1*xmax;
     }
   if (xmin == 0.0)
     {
	xmax = 1.0;
	xmin = 0.1;
     }
   if (tweaked)
     () = fprintf (stderr, "*** Warning: Invalid world coordinates for log axis\n");
   return xmin, xmax;
}

private define log_world_to_normalized (x, xmin, xmax)
{
   (xmin, xmax) = check_xmin_xmax_for_log (xmin, xmax);
   variable i = where (x <= 0.0);
   if (length (i))
     {
	if (typeof (x) == Array_Type)
	  {
	     x = @x;
	     x[i] = 0.1*xmin;
	     x[where(x == 0.0)] = xmin;
	  } 
	else if (x == 0.0) x = xmin;
	else x = 0.1*xmin;
     }
   return linear_world_to_normalized (log10(x), log10(xmin), log10(xmax));
}

private define log_normalized_to_world (t, xmin, xmax)
{
   variable x = linear_normalized_to_world (t, log10(xmin), log10(xmax));
   return 10.0^x;
}
xfig_plot_add_transform ("log", &log_world_to_normalized, &log_normalized_to_world);

private define resid_mapping (x, n)
{
   variable y = Double_Type[length(x)];
   variable i = where (x >= 1);
   y[i] = 2.0 - 1.0/(x[i]^n);
   i = where (x < 1.0);
   y[i] = x[i]^n;
   if (typeof (x) != Array_Type)
     y = y[0];
   return y;
}

private define resid_world_to_normalized (x, xmin, xmax)
{
   variable n = 4.0;
   x = resid_mapping (x, n);
   xmin = resid_mapping (xmin, n);
   xmax = resid_mapping (xmax, n);
   return linear_world_to_normalized (x, xmin, xmax);
}

private define resid_normalized_to_world (t, xmin, xmax)
{
   xmin = resid_mapping (xmin);
   xmax = resid_mapping (xmax);
   variable x = linear_normalized_to_world (t, xmin, xmax);
   % FIXME
   return x;
}
xfig_plot_add_transform ("resid", &resid_world_to_normalized, &resid_normalized_to_world);


private define make_tics (axis, tics, X, xmin, xmax, dX, dY, ticlen, add_tic_labels)
{
   xmin = double(xmin);
   xmax = double(xmax);
   variable den = (xmax - xmin);
   variable list = xfig_new_polyline_list ();
   variable world_to_normalized = axis.wcs_transform.world_to_normalized;

   dY = vector_mul (ticlen, dY);
   variable Xmax = vector_sum (X, dX);

   variable tic_labels = NULL;
   if (add_tic_labels)
     {
	tic_labels = axis.tic_labels;
     }

   _for (0, length(tics)-1, 1)
     {
	variable i = ();
	variable x = tics[i];
	
	x = (@world_to_normalized)(double (x), xmin, xmax);

	variable X0 = vector_sum (X, vector_mul(x, dX));
	variable X1 = vector_sum (X0, dY);

	variable tic = xfig_make_polyline (vector ([X0.x, X1.x],
						   [X0.y, X1.y],
						   [X0.z, X1.z]));
	xfig_polyline_list_insert (list, tic);
	if (tic_labels != NULL)
	  {
	     xfig_justify_object (tic_labels[i], X0 + axis.tic_labels_tweak, axis.tic_labels_just);
	     if (dX.y != 0)
	       {
		  % y tic
		  variable y0, y1, dy = 0;
		  (,,y0,y1,,) = xfig_get_object_bbox (tic_labels[i]);
		  if (y1 > Xmax.y)
		    dy = Xmax.y - y1;
		  if (y0 < X.y)
		    dy = X.y - y0;
		  if (dy != 0)
		    xfig_translate_object (tic_labels[i], vector (0,dy,0));
	       }
	  }
     }
   xfig_set_pen_color (list, axis.color);
   xfig_set_line_style (list, axis.line_style);
   xfig_set_thickness (list, axis.thickness);
   xfig_set_depth (list, axis.depth);
   return list;
}

private define make_tic_marks_and_tic_labels (axis)
{
   if (axis == NULL)
     return;
   
   variable X = axis.X, dX = axis.dX, dY = axis.dY;
   variable xmin = axis.xmin;
   variable xmax = axis.xmax;
   variable islog = axis.islog;

   variable X1 = vector_sum (X, dX);
   variable line = xfig_new_polyline (vector ([X.x, X1.x],[X.y,X1.y],[X.z,X1.z]));
   xfig_set_pen_color (line, axis.color);
   xfig_set_line_style (line, axis.line_style);
   xfig_set_thickness (line, axis.thickness);
   xfig_set_depth (line, axis.depth);
   
   axis.line = line;
   axis.minor_tic_marks = NULL;
   axis.major_tic_marks = NULL;

   variable ticlen;
   variable tics;
   tics = axis.major_tics;

   if (tics != NULL)
     {
	ticlen = 0.25;
	axis.major_tic_marks = make_tics (axis, tics, X, xmin, xmax, dX, dY, 
					  ticlen, 1);
     }

   tics = axis.minor_tics;
   if (tics != NULL)
     {
	ticlen = 0.15;
	axis.minor_tic_marks = make_tics (axis, tics, X, xmin, xmax, dX, dY, 
					  ticlen, 0);
     }

   % Convert the tic labels to a compound object for ease of manipulation
   variable compound = xfig_new_compound_list ();
   foreach (axis.tic_labels)
     {
	variable label = ();
	xfig_compound_list_insert (compound, label);
     }
   axis.tic_labels = compound;
}

private define render_tics_for_axis (axis, fp)
{
   if (axis == NULL)
     return;

   xfig_render_object (axis.line, fp);
   xfig_render_object (axis.major_tic_marks, fp);
   xfig_render_object (axis.tic_labels, fp);
   xfig_render_object (axis.minor_tic_marks, fp);
   xfig_render_object (axis.axis_label, fp);
}

private define render_plot_axes (p, fp)
{
   variable axis;
   variable w = p.plot_width;
   variable h = p.plot_height;
   variable tic, ticlen;
   
   variable dX, dY, xmin, xmax;

   axis = p.x1axis;
   render_tics_for_axis (axis, fp);

   axis = p.y1axis;
   render_tics_for_axis (axis, fp);

   axis = p.x2axis;
   render_tics_for_axis (axis, fp);

   axis = p.y2axis;
   render_tics_for_axis (axis, fp);
}

private define translate_axis (axis, X)
{
   axis.X = vector_sum (axis.X, X);
   xfig_translate_object (axis.line, X);
   xfig_translate_object (axis.major_tic_marks, X);
   xfig_translate_object (axis.minor_tic_marks, X);
   xfig_translate_object (axis.tic_labels, X);
   xfig_translate_object (axis.axis_label, X);
}

private define plot_translate (p, X)
{
   p.X = vector_sum (p.X, X);
   translate_axis (p.x1axis, X);
   translate_axis (p.x2axis, X);
   translate_axis (p.y1axis, X);
   translate_axis (p.y2axis, X);
   xfig_translate_object (p.object_list, X);
}

private define rotate_axis (axis, normal, theta)
{
   axis.X = vector_rotate (axis.X, normal, theta);
   xfig_rotate_object (axis.line, normal, theta);
   xfig_rotate_object (axis.major_tic_marks, normal, theta);
   xfig_rotate_object (axis.minor_tic_marks, normal, theta);
   xfig_rotate_object (axis.tic_labels, normal, theta);
   xfig_rotate_object (axis.axis_label, normal, theta);
}

private define plot_rotate (p, normal, theta)
{
#iffalse
   vmessage ("plot_rotate not implemented");
   return;
#else
   p.X = vector_rotate (p.X, normal, theta);
   rotate_axis (p.x1axis, normal, theta);
   rotate_axis (p.x2axis, normal, theta);
   rotate_axis (p.y1axis, normal, theta);
   rotate_axis (p.y2axis, normal, theta);
   xfig_rotate_object (p.object_list, normal, theta);
#endif
}

private define plot_scale (p, sx, sy, sz)
{
   variable X = p.X;
   X.x *= sx;
   X.y *= sy;
   X.z *= sz;
}

private define plot_set_attr (p, attr, val)
{
}

private define get_axis_bbox (axis)
{
   return xfig_get_object_bbox (xfig_new_compound (axis.line, axis.tic_labels, axis.axis_label));
}

private define plot_get_bbox (p)
{
   vmessage ("Warning: plot bounding box not fully supported");
   variable xmin, xmax, ymin, ymax, zmin, zmax;
   variable x0, x1, y0, y1, z0, z1;

   (xmin, xmax, ymin, ymax, zmin, zmax) = get_axis_bbox (p.x1axis);
   foreach ([p.x2axis, p.y1axis, p.y2axis])
     {
	variable axis = ();
	(x0, x1, y0, y1, z0, z1) = get_axis_bbox (axis);
	if (x0 < xmin) xmin = x0;
	if (x1 > xmax) xmax = x1;
	if (y0 < ymin) ymin = y0;
	if (y1 > ymax) ymax = y1;
	if (z0 < zmin) zmin = z0;
	if (z1 > zmax) zmax = z1;
     }
   return xmin, xmax, ymin, ymax, zmin, zmax;
}

private define plot_render (p, fp)
{
   variable plot_width = p.plot_width;
   variable plot_height= p.plot_height;

   xfig_render_object (p.object_list, fp);
   % It looks better when the axes are rendered after the plot object
   render_plot_axes (p, fp);
}

private define construct_tic_labels (axis, tics)
{
   variable format = axis.tic_label_format;
   variable i, alt_fmt = NULL;
   variable tic_labels;

   if (axis.islog)
     {
	if (format == NULL)
	  {
	     format = "\\bf 10$\\bm^{%g}$";
	     alt_fmt = "\\bf %.5g";
	  }
	tic_labels = array_map (String_Type, &sprintf, format, log10(tics));
	if (alt_fmt != NULL)
	  {
	     i = where ((tics >= 0.01) and (tics < 99999.5));
	     if (length (i))
	       tic_labels[i] = array_map (String_Type, &sprintf, alt_fmt, tics[i]);
	  }
     }
   else 
     {
	if (format == NULL)
	  {
	     format = "\\bf %.5g";
	     alt_fmt = "\\bf %g$\\bf\\bm\\cdot 10^{%d}$";
	  }
	tic_labels = array_map (String_Type, &sprintf, format, tics);
	if (alt_fmt != NULL)
	  {
	     variable abs_tics = abs(tics);
	     i = where (((abs_tics > 0) and (abs_tics < 1e-4))
			or (abs_tics >= 99999.5));
	     if (length(i))
	       {
		  variable a, b;  % x = a*10^b; log10(x)=log10(a)+b;
		  a = log10(abs_tics[i]);
		  variable j = where (a < 0);
		  (b,a) = (int(a), a-int(a));
		  a[j]++;
		  b[j]--;
		  a = 10.0^a;
		  a[where(tics[i]<0)] *= -1;
		  tic_labels[i] = array_map (String_Type, &sprintf, alt_fmt, 
					     a, b);
	       }
	  }
     }
   return tic_labels;
}

private define make_tic_labels (axis, tic_labels_just, tweakx, tweaky)
{
   variable tics = axis.major_tics;
   variable islog = axis.islog;
   variable tic_labels = axis.tic_labels;
   variable max_tic_h = 0, max_tic_w = 0;

   if ((tics == NULL) or (length(tics) == 0))
     return;
   
   if (tic_labels == NULL)
     tic_labels = construct_tic_labels (axis, tics);

   tic_labels = array_map (Struct_Type, &xfig_new_text, tic_labels);
   variable tic_labels_dX = Struct_Type[length(tic_labels)];
   _for (0, length(tic_labels)-1, 1)
     {
	variable i = ();
	variable w, h;
	(w,h) = xfig_get_pict_bbox (tic_labels[i]);
	if (max_tic_w < w)
	  max_tic_w = w;
	if (max_tic_h < h)
	  max_tic_h = h;
     }

   axis.max_tic_h = max_tic_h + 2*abs(tweaky);
   axis.max_tic_w = max_tic_w + 2*abs(tweakx);
   axis.tic_labels_tweak = vector (tweakx, tweaky, 0);
   axis.tic_labels_just = tic_labels_just;
   axis.tic_labels = tic_labels;
}

private define make_tic_intervals (axis)
{
   variable xmin = axis.xmin;
   variable xmax = axis.xmax;

   if (xmax < xmin)
     (xmin, xmax) = (xmax, xmin);

   variable islog = axis.islog;
   variable major_tics;
   variable num_minor;
   if (islog)
     {
	(xmin, xmax) = check_xmin_xmax_for_log (xmin, xmax);
     }
   
   (major_tics, num_minor) = get_major_tics (xmin, xmax, islog, axis.maxtics);

   if (islog)
     {
	%major_tics = 10.0^major_tics;
	num_minor = 8;
     }

   variable minor_tics = Double_Type[num_minor*length(major_tics)];
   variable major_tic_interval = major_tics[1] - major_tics[0];
   variable minor_tic_interval;
   variable i, j;

   j = [1:num_minor];
   i = j-1;
   if (islog)
     {
	j = log10 (j+1);
	minor_tic_interval = 1.0;
     }
   else
     minor_tic_interval = major_tic_interval/(num_minor+1.0);

   foreach (major_tics)
     {
	variable major_tic = ();
	minor_tics[i] = major_tic + j*minor_tic_interval;
	i += num_minor;
     }
   
   if (islog)
     {
	minor_tics = 10.0^minor_tics;
	major_tics = 10.0^major_tics;
     }
   axis.major_tics = major_tics[where ((major_tics >= xmin) and (major_tics <= xmax))];
   axis.minor_tics = minor_tics[where ((minor_tics >= xmin) and (minor_tics <= xmax))];
}

private define allocate_axis_type (len, maxtics, xpos, ypos, dirx, diry, ticdirx, ticdiry)
{
   variable a = @Plot_Axis_Type;
   a.xmin = 0.1;
   a.xmax = 1.0;
   a.islog = 0;
   setup_axis_wcs (a, "linear");
   a.maxtics = maxtics;
   a.max_tic_w = 0.0;
   a.max_tic_h = 0.0;
   a.X = vector (xpos, ypos, 0);
   a.dX = vector (dirx*len, diry*len, 0);
   a.dY = vector (ticdirx, ticdiry,0);
   return a;
}


%!%+
%\function{xfig_plot_new}
%\synopsis{Create a new plot object}
%\usage{w = xfig_plot_new ( [Int_Type width, Int_Type height] );}
%\description
% This function creates a new plot object of the specified width and height.
% If the width and height parameters are not given, defaults will be used.
% The width and height values specify the size of the plotting area and do not
% include the space for tic marks and labels.
%\example
%#v+
%   w = xfig_plot_new ();
%#v-
%\seealso{xfig_plot_define_world, xfig_render_object}
%!%-
define xfig_plot_new ()
{
   variable w, h;
   if (_NARGS == 0)
     (14, 10);
   (w, h) = ();

   variable p = @XFig_Plot_Type;
   p.plot_width = w;
   p.plot_height = h;
   variable maxticsx = int(w*0.5 + 1.5);
   variable maxticsy = int(h+1.5);
   p.x1axis = allocate_axis_type (w, maxticsx, (0,0), (1,0), (0,1));
   p.y1axis = allocate_axis_type (h, maxticsy, (0,0), (0,1), (1,0));
   p.x2axis = allocate_axis_type (w, maxticsx, (0,h), (1,0), (0,-1));
   p.y2axis = allocate_axis_type (h, maxticsy, (w,0), (0,1), (-1,0));

   p.line_color = "black";
   p.line_style = 0;
   p.thickness = 2;
   p.point_color = "black";
   p.point_size = 1;
   p.line_depth = DEFAULT_LINE_DEPTH;
   p.point_depth = DEFAULT_POINT_DEPTH;
   p.axis_depth = DEFAULT_AXIS_DEPTH;
   p.image_depth = DEFAULT_IMAGE_DEPTH;

   p.X = vector(0,0,0);
   p.object_list = xfig_new_compound_list ();

   variable obj = xfig_new_object (p);
   obj.render_fun = &plot_render;
   obj.rotate_fun = &plot_rotate;
   obj.translate_fun = &plot_translate;
   obj.scale_fun = &plot_scale;
   obj.set_attr_fun = &plot_set_attr;
   obj.get_bbox_fun = &plot_get_bbox;
   obj.flags |= XFIG_RENDER_AS_COMPOUND;
   return obj;
}

private define get_world_min_max (x0, x1)
{
   if (isnan (x0) or isnan (x1) or isinf (x0) or isinf (x1))
     {
	() = fprintf (stderr, "xfig_plot_define_world: Axis limits must be finite.\n");
	return 0.1, 1.0;
     }
       
   if (x0 == x1)
     {
	x0 = 0.5*x0;
	x1 = 2.0*x0;
	if (x0 == x1)
	  {
	     () = fprintf (stderr, "xfig_plot_define_world: invalid world limits");
	     x0 = 0.0;
	     x1 = 1.0;
	  }
     }
   return x0, x1;
}

private define get_define_world_args (nargs)
{
   variable xdata, ydata;
   variable x0, x1, y0, y1;
   switch (nargs)
     {
      case 3:
	(xdata, ydata) = ();
	(x0, x1) = (min(xdata), max(xdata));
	(y0, y1) = (min(ydata), max(ydata));
     }
     {
      case 5:
	(x0, x1, y0, y1) = ();
     }
     {
	usage ("xfig_plot_define_world (plotwin, [x0, x1], [y0, y1])");
     }
   variable w = ();
   return w, get_world_min_max (x0, x1), get_world_min_max (y0, y1);
}

   
define xfig_plot_define_world1 ()
{
   variable p, xmin, xmax, ymin, ymax;
   (p, xmin, xmax, ymin, ymax) = get_define_world_args (_NARGS);
   variable axis;
   p = p.object;
   axis = p.x1axis; axis.xmin = double(xmin); axis.xmax = double(xmax);
   axis = p.y1axis; axis.xmin = double(ymin); axis.xmax = double(ymax);
}

define xfig_plot_define_world2 ()
{
   variable p, xmin, xmax, ymin, ymax;
   (p, xmin, xmax, ymin, ymax) = get_define_world_args (_NARGS);
   variable axis;
   p = p.object;
   axis = p.x2axis; axis.xmin = double(xmin); axis.xmax = double(xmax);
   axis = p.y2axis; axis.xmin = double(ymin); axis.xmax = double(ymax);
}

define xfig_plot_define_world ()
{
   variable p, xmin, xmax, ymin, ymax;
   (p, xmin, xmax, ymin, ymax) = get_define_world_args (_NARGS);

   xfig_plot_define_world1 (p, xmin, xmax, ymin, ymax);
   xfig_plot_define_world2 (p, xmin, xmax, ymin, ymax);
}

private define setup_axis_tics (p, axis, geom, want_tic_labels)
{
   variable ticofs_x = geom[0], ticofs_y = geom[1], tic_tweak_x = geom[2], 
     tic_tweak_y = geom[3], tx = geom[4], ty = geom[5], theta = geom[6];

   if (want_tic_labels) 
     make_tic_labels (axis, vector (ticofs_x, ticofs_y, 0), 
		      tic_tweak_x, tic_tweak_y);
   %else axis.tic_labels = NULL;

   axis.color = p.line_color;
   axis.line_style = p.line_style;
   axis.thickness = p.thickness;
   axis.depth = p.axis_depth;

   make_tic_marks_and_tic_labels (axis);
}

private define add_axis (p, axis, wcs_type, label,
			want_tic_labels, geom)
{
   variable ticofs_x = geom[0], ticofs_y = geom[1], tic_tweak_x = geom[2], 
     tic_tweak_y = geom[3], tx = geom[4], ty = geom[5], theta = geom[6];

   setup_axis_wcs (axis, wcs_type);
   make_tic_intervals (axis);

   setup_axis_tics (p, axis, geom, want_tic_labels);

   if (label == NULL)
     return;

   label = xfig_new_text (label);
   if (theta != 0) xfig_rotate_pict (label, theta);

   variable X = 0.5 * (2*axis.X + axis.dX);
   X += vector (tx*axis.max_tic_w, ty*axis.max_tic_h, 0);

   xfig_justify_object (label, X, axis.tic_labels_just);
   axis.axis_label = label;
}

% Usage:
% xfig_add_*_axis (obj, islog|wcs, label [,make_tic_labels])
% Here major/minor_tics is an array of world coord system values where the 
% major/minor tics will be placed.
private define get_add_axis_args (axis_name, nargs)
{
   variable p, axis = NULL, wcs_type, label,
     want_tic_labels = 1, major_tics = NULL, minor_tics = NULL;

   switch (nargs)
     {
      case 4:
	want_tic_labels = ();
     }
     {
	if (nargs != 3)
	  usage ("xfig_add_*_axis (obj, islog|wcs, label [,make_tic_labels])");
     }
   (p, wcs_type, label) = ();
   if (typeof (wcs_type) != String_Type)
     {
	if (wcs_type == 1)
	  wcs_type = "log";
	else wcs_type = "linear";
     }

   if (axis_name != NULL)
     {
	p = p.object;
	axis = get_struct_field (p, axis_name);
     }
   return p, axis, wcs_type, label, want_tic_labels;
}


private variable X1_Axis_Geom = [ 0.0,   0.5,  0.0, -0.1,   0.0, -1.0,   0];
private variable X2_Axis_Geom = [ 0.0,  -0.5,  0.0,  0.0,   0.1,  1.0,   0];
private variable Y1_Axis_Geom = [ 0.5,   0.0, -0.1,  0.0,  -1.0,  0.0,  90];
private variable Y2_Axis_Geom = [-0.5,   0.0,  0.1,  0.0,   1.0,  0.0, -90];

% Usage: xfig_plot_set_*_tics (win, major_tics [,tic_labels,[minor_tics]])
% If tic_labels is NULL or not present then they will be generated.  
% If tic_labels is "", then none will be generated.

private define pop_set_tic_args (fun, nargs)
{
   variable win, major_tics, tic_labels = NULL, minor_tics = NULL;
   switch (nargs)
     {
      case 4:
	(tic_labels,minor_tics) = ();
     }
     {
      case 3:
	tic_labels = ();
     }
     {
	if (_NARGS != 2)
	  usage ("%s (win, major_tics [,major_tic_labels [,minor_tics]])", fun);
     }
   (win, major_tics) = ();
   return win, major_tics, tic_labels, minor_tics;
}

private define set_xx_axis_tics (axis_name, fun, geom, nargs)
{
   variable win, major_tics, tic_labels, minor_tics;
   (win, major_tics, tic_labels, minor_tics) = pop_set_tic_args (fun, nargs);
   variable obj = win.object;
   variable axis = get_struct_field (obj, axis_name);
   variable want_tic_labels = (tic_labels != NULL);
   if (typeof (tic_labels) == String_Type)
     {
	want_tic_labels = (tic_labels != "");
	!if (want_tic_labels) tic_labels = NULL;
     }

   variable xmin = axis.xmin, xmax = axis.xmax;
   variable i;
   
   if (major_tics != NULL)
     {
	i = where ((major_tics >= xmin) and (major_tics <= xmax));
	major_tics = major_tics[i];
	if (typeof (tic_labels) == Array_Type)
	  tic_labels = tic_labels[i];
     }
   if (minor_tics != NULL)
     minor_tics = minor_tics[where ((minor_tics >= xmin) and (minor_tics <= xmax))];

   axis.tic_labels = tic_labels;
   axis.major_tics = major_tics;
   axis.minor_tics = minor_tics;
   setup_axis_tics (obj, axis, geom, want_tic_labels);
}

define xfig_plot_set_x1_tics ()
{
   set_xx_axis_tics ("x1axis", _function_name, X1_Axis_Geom, _NARGS);
}

define xfig_plot_set_x2_tics ()
{
   set_xx_axis_tics ("x2axis", _function_name, X2_Axis_Geom, _NARGS);
}

define xfig_plot_set_y1_tics ()
{
   set_xx_axis_tics ("y1axis", _function_name, Y1_Axis_Geom, _NARGS);
}

define xfig_plot_set_y2_tics ()
{
   set_xx_axis_tics ("y2axis", _function_name, Y2_Axis_Geom, _NARGS);
}

define xfig_plot_set_x_tics ()
{
   variable win, major_tics, tic_labels, minor_tics;
   (win, major_tics, tic_labels, minor_tics) = pop_set_tic_args (_function_name, _NARGS);
   
   xfig_plot_set_x1_tics (win, major_tics, tic_labels, minor_tics);
   xfig_plot_set_x2_tics (win, major_tics, "", minor_tics);
}

define xfig_plot_set_y_tics ()
{
   variable win, major_tics, tic_labels, minor_tics;
   (win, major_tics, tic_labels, minor_tics) = pop_set_tic_args (_function_name, _NARGS);
   
   xfig_plot_set_y1_tics (win, major_tics, tic_labels, minor_tics);
   xfig_plot_set_y2_tics (win, major_tics, "", minor_tics);
}


define xfig_plot_add_x1_axis ()
{
   add_axis (get_add_axis_args ("x1axis", _NARGS), X1_Axis_Geom);
}

define xfig_plot_add_x2_axis ()
{
   add_axis (get_add_axis_args ("x2axis", _NARGS), X2_Axis_Geom);
}

define xfig_plot_add_y1_axis ()
{
   add_axis (get_add_axis_args ("y1axis", _NARGS), Y1_Axis_Geom);
}


define xfig_plot_add_y2_axis ()
{
   add_axis (get_add_axis_args ("y2axis", _NARGS), Y2_Axis_Geom);
}

define xfig_plot_add_x_axis ()
{
   variable p, axis, wcs_type, label, want_tic_labels;
   (p, axis, wcs_type, label, want_tic_labels)
     = get_add_axis_args (NULL, _NARGS);

   xfig_plot_add_x1_axis (p, wcs_type, label, want_tic_labels);
   xfig_plot_add_x2_axis (p, wcs_type, NULL, 0);
}

define xfig_plot_add_y_axis ()
{
   variable p, axis, wcs_type, label, want_tic_labels;
   (p, axis, wcs_type, label, want_tic_labels)
       = get_add_axis_args (NULL, _NARGS);

   xfig_plot_add_y1_axis (p, wcs_type, label, want_tic_labels);
   xfig_plot_add_y2_axis (p, wcs_type, NULL, 0);
}

private define scale_coords_for_axis (axis, axis_len, x)
{
   variable x0 = axis.xmin;
   variable x1 = axis.xmax;
   return axis_len * (@axis.wcs_transform.world_to_normalized) (double(x), x0, x1);
}

private define make_nsided_polygon (n, x0, y0, radius)
{
   variable theta = [0:n]*(2*PI/n);
   variable x = x0 + radius * cos (theta);
   variable y = y0 + radius * sin (theta);
   return x, y;
}

define xfig_plot_lines (p, x, y)
{
   p = p.object;
   variable ax = p.x1axis, ay = p.y1axis;
   variable w = p.plot_width, h = p.plot_height;
   
   if (length (x) < 2)
     return;

   x = scale_coords_for_axis (ax, w, x);
   y = scale_coords_for_axis (ay, h, y);
   variable bad = Int_Type [length(x)+1];
   bad[-1] = 1;

   variable i = where ((x != x) or (y != y));
   bad[i] = 1;

   variable i0 = 0;
   foreach (where (bad))
     {
	i = ();
	if (i != i0)
	  {
	     variable ii = [i0:i-1];
	     variable lines = xfig_clip_polyline2d (x[ii], y[ii], 0, w, 0, h);
	     xfig_translate_object (lines, p.X);
	     xfig_set_depth (lines, p.line_depth);
	     xfig_set_thickness (lines, p.thickness);
	     xfig_set_pen_color (lines, p.line_color);
	     xfig_set_line_style (lines, p.line_style);
	     xfig_compound_list_insert (p.object_list, lines);
	  }
	i0 = i+1;
     }
}

private define pop_plot_err_parms (nargs)
{
   variable p, x, y, dy, term_factor = 1;
   if (nargs == 5)
     term_factor = ();
   (p, x, y, dy) = ();

   variable i = where (not (isnan(x) or isnan(y) or isnan (dy)));
   if (length (i) != length (x))
     {	
	x = x[i];
	y = y[i];
	if (dy == Array_Type)
	  dy = dy[i];
	else if (isnan (dy)) dy = dy[i];
     }
   return p.object, x, y, dy, term_factor;
}

private define insert_errbar_list (p, lines)
{
   xfig_translate_object (lines, p.X);
   xfig_set_depth (lines, p.line_depth);
   xfig_set_thickness (lines, p.thickness);
   xfig_set_pen_color (lines, p.line_color);
   xfig_set_line_style (lines, p.line_style);
   xfig_compound_list_insert (p.object_list, lines);
}

define xfig_plot_erry ()
{
   variable p, x, y, dy, term_factor;
   (p, x, y, dy, term_factor) = pop_plot_err_parms (_NARGS);
   variable ax = p.x1axis, ay = p.y1axis;
   variable w = p.plot_width, h = p.plot_height;

   x = scale_coords_for_axis (ax, w, x);
   variable y0 = scale_coords_for_axis (ay, h, y-dy);
   variable y1 = scale_coords_for_axis (ay, h, y+dy);

   variable dt = abs (ERRBAR_TERMINAL_SIZE * term_factor);
   variable dz = [0.0,0.0];
   variable lines = xfig_new_polyline_list ();
   variable i;
   _for i (0, length (x)-1, 1)
     {
	variable x_i = x[i];
	variable x0_i = x_i - dt;
	variable x1_i = x_i + dt;
	variable y0_i = y0[i];
	variable y1_i = y1[i];
	
	if (x1_i <= 0) continue;
	if (x0_i >= w) continue;
	if (y0_i >= h) continue;
	if (y1_i <= 0) continue;

	x0_i = _max (x0_i, 0);
	x1_i = _min (x1_i, w);

	variable obj;
	variable dx = [x0_i, x1_i];
	
	if (y1_i < h)
	  {
	     if (term_factor)
	       xfig_polyline_list_insert (lines, xfig_make_polyline (vector (dx, [y1_i, y1_i], dz)));
	  }
	else y1_i = h;

	if (y0_i > 0)
	  {
	     if (term_factor)
	       xfig_polyline_list_insert (lines, xfig_make_polyline (vector (dx, [y0_i, y0_i], dz)));
	  }
	else y0_i = 0;

	xfig_polyline_list_insert (lines, xfig_make_polyline (vector ([x_i, x_i], [y0_i,y1_i], dz)));
     }
   insert_errbar_list (p, lines);
}

define xfig_plot_errx ()
{
   variable p, x, y, dx, term_factor;
   (p, x, y, dx, term_factor) = pop_plot_err_parms (_NARGS);
   variable ax = p.x1axis, ay = p.y1axis;
   variable w = p.plot_width, h = p.plot_height;
   
   y = scale_coords_for_axis (ay, h, y);
   variable x0 = scale_coords_for_axis (ax, w, x-dx);
   variable x1 = scale_coords_for_axis (ax, w, x+dx);

   variable dt = abs (ERRBAR_TERMINAL_SIZE * term_factor);
   variable dz = [0.0,0.0];
   variable lines = xfig_new_polyline_list ();
   variable i;
   _for i (0, length (x)-1, 1)
     {
	variable y_i = y[i];
	variable y0_i = y_i - dt;
	variable y1_i = y_i + dt;
	variable x0_i = x0[i];
	variable x1_i = x1[i];
	
	if (x1_i <= 0) continue;
	if (x0_i >= w) continue;
	if (y0_i >= h) continue;
	if (y1_i <= 0) continue;

	y0_i = _max (y0_i, 0);
	y1_i = _min (y1_i, h);

	variable obj;
	variable dy = [y0_i, y1_i];
	
	if (x1_i < w)
	  {
	     if (term_factor)
	       xfig_polyline_list_insert (lines, xfig_make_polyline (vector ([x1_i, x1_i], dy, dz)));
	  }
	else x1_i = w;

	if (x0_i > 0)
	  {
	     if (term_factor)
	       xfig_polyline_list_insert (lines, xfig_make_polyline (vector ([x0_i, x0_i], dy, dz)));
	  }
	else x0_i = 0;

	xfig_polyline_list_insert (lines, xfig_make_polyline (vector ([x0_i, x1_i], [y_i,y_i], dz)));
     }
   insert_errbar_list (p, lines);
}

private variable Make_Symbol_Funs = Assoc_Type[Ref_Type];

%!%+
%\function{xfig_plot_add_symbol}
%\synopsis{Add a plot symbol}
%\usage{xfig_plot_add_symbol (String_Type name, Ref_Type funct)}
%\description
% This function may be used to add a new plot symbol of the specified name.
% The \exmp{funct} parameter specifies a function to be called to create the 
% symbol.  It will be called with a single parameter: a value representing the 
% scale size of the symbol in fig units.  The function must return two arrays 
% representing the X and Y coordinates of the polygons that represent
% the symbol.  The center of the object is taken to be (0,0).  If more than one
% polygon is require to represent the object, an array of arrays may be
% returned.
%!%-
define xfig_plot_add_symbol (name, fun)
{
   Make_Symbol_Funs[name] = fun;
}

private define make_triangle (radius)
{
   variable t = [-30, 90, 210, -30] * (PI/180.0);
   return radius * cos (t), radius * sin(t);
}
xfig_plot_add_symbol ("triangle", &make_triangle);
xfig_plot_add_symbol ("triangle-up", &make_triangle);

private define make_triangle_down (radius)
{
   variable t = [30, 150, 270, 30] * (PI/180.0);
   return radius * cos (t), radius * sin(t);
}
xfig_plot_add_symbol ("triangle-down", &make_triangle_down);

private define make_diamond (radius)
{
   variable t = [0, 90, 180, 270, 0] * (PI/180.0);
   return radius * cos (t), radius * sin(t);
}
xfig_plot_add_symbol ("diamond", &make_diamond);

private define make_square (radius)
{
   variable t = [-45, 45, 135, 225, -45] * (PI/180.0);
   return radius * cos (t), radius * sin(t);
}
xfig_plot_add_symbol ("square", &make_square);

private define make_plus (radius)
{
   variable x = Array_Type[2];
   variable y = Array_Type[2];
   x[0] = [-radius, radius];  y[0] = [0,0];
   x[1] = [0, 0]; y[1] = [-radius, radius];
   return x,y;
}
   
define xfig_plot_symbols (p, x, y, symbol)
{
   p = p.object;
   variable ax = p.x1axis, ay = p.y1axis;
   
   variable bad = Int_Type [length(x)+1];
   bad[-1] = 1;

   variable w = p.plot_width, h = p.plot_height;

   x = scale_coords_for_axis (ax, w, x);
   y = scale_coords_for_axis (ay, h, y);

   variable point_size = p.point_size;
   if (point_size == 0)
     point_size = 1;
   point_size *= 5;

   variable fun = Make_Symbol_Funs [symbol];
   variable radius = xfig_scale_from_inches (0.5*point_size/80.0);
   foreach (where (bad == 0))
     {
	variable i = ();
	variable xx, yy, lines;
	(xx,yy) = (@fun)(radius);
	if (_typeof (xx) == Array_Type)
	  {
	     _for (0, length (xx)-1, 1)
	       {
		  variable j = ();
		  variable xx_j = xx[j];
		  variable yy_j = yy[j];
		  xx_j += x[i];
		  yy_j += y[i];
		  lines = xfig_clip_polygon2d (xx_j, yy_j, 0, w, 0, h);
		  xfig_set_pen_color (lines, p.point_color);
		  xfig_set_fill_color (lines, p.point_color);
		  xfig_set_depth (lines, p.point_depth);
		  xfig_translate_object (lines, p.X);
		  xfig_compound_list_insert (p.object_list, lines);
	       }
	     continue;
	  }
	xx += x[i];
	yy += y[i];
	lines = xfig_clip_polygon2d (xx, yy, 0, w, 0, h);
	xfig_set_pen_color (lines, p.point_color);
	xfig_set_fill_color (lines, p.point_color);
	xfig_set_area_fill (lines, 20);
	xfig_set_depth (lines, p.point_depth);
	xfig_translate_object (lines, p.X);
	xfig_compound_list_insert (p.object_list, lines);
     }
}

define xfig_plot_points (p, x, y)
{
   p = p.object;
   variable ax = p.x1axis, ay = p.y1axis;
   
   variable bad = Int_Type [length(x)+1];
   bad[-1] = 1;

   variable w = p.plot_width, h = p.plot_height;

   x = scale_coords_for_axis (ax, w, x);
   y = scale_coords_for_axis (ay, h, y);

   variable nsides;
   variable point_size = p.point_size;
   if (point_size == 0)
     nsides = 1;
   else if (point_size < 16)
     nsides = 4 + (point_size-1)*2;
   else 
     nsides = 32;

   variable radius = xfig_scale_from_inches (0.5*point_size/80.0);
   foreach (where (bad == 0))
     {
	variable i = ();
	variable xx, yy;
	(xx,yy) = make_nsided_polygon (nsides, x[i], y[i], radius);
	variable lines = xfig_clip_polygon2d (xx, yy, 0, w, 0, h);
	xfig_set_fill_color (lines, p.point_color);
	xfig_set_pen_color (lines, p.point_color);
	xfig_set_area_fill (lines, 20);
	xfig_set_depth (lines, p.point_depth);
	xfig_translate_object (lines, p.X);
	xfig_compound_list_insert (p.object_list, lines);
     }
}

% Usage: xfig_plot_histogram (w, x, y [,fill_color, area_fill])
define xfig_plot_histogram (w, xpts, ypts)
{
   variable len = length(xpts);
   variable len2 = 2 + 2*len;
   variable x = Double_Type[len2];
   variable y = Double_Type[len2];
   variable i;
   y[0] = 0;        
   x[[0:len2-3:2]] = xpts;
   x[[1:len2-2:2]] = xpts;
   y[[1:len2-3:2]] = ypts;
   y[[2:len2-2:2]] = ypts;
   x[-1] = xpts[-1] + (xpts[-1]-xpts[-2]);
   x[-2] = x[-1];
   y[where (isnan (y))] = 0.0;
   
#iffalse
   y[-1] = ypts[-1];
#else
   y[-1] = 0;
#endif
   xfig_plot_lines (w, x, y);
}


define xfig_plot_shaded_histogram (p, x, y, color, area_fill)
{
   p = p.object;
   variable ax = p.x1axis, ay = p.y1axis;
   variable w = p.plot_width, h = p.plot_height;
   x = scale_coords_for_axis (ax, w, x);
   y = scale_coords_for_axis (ay, h, y);

   variable y0 = scale_coords_for_axis (ay, h, 0.0);
   variable i = where ((x>= 0) and (x <= w));
   x = x[i]; y = y[i];
   y[where(isnan(y))] = y0;
   y[where (y < y0)] = y0; 
   y[where (y > h)] = h;

   variable list = xfig_new_polyline_list ();
   _for (0, length (x)-2, 1)
     {
	i = ();
	variable x0 = x[i];
	variable x1 = x[i+1];
	variable y1 = y[i];
	
	variable bin = xfig_make_polyline (vector([x0, x0, x1, x1], [y0,y1,y1,y0], [0.0,0.0,0.0,0.0]));
	xfig_polyline_list_insert (list, bin);
     }
   xfig_translate_object (list, p.X);
   xfig_set_depth (list, p.line_depth-1);
   xfig_set_pen_color (list, p.line_color);
   xfig_set_line_style (list, p.line_style);
   xfig_set_fill_color (list, color);
   xfig_set_area_fill (list, area_fill);
   xfig_compound_list_insert (p.object_list, list);
}

define xfig_plot_set_line_color (p, color)
{
   p.object.line_color = color;
}

define xfig_plot_set_line_style (p, style)
{
   p.object.line_style = style;
}

define xfig_plot_set_line_thickness (p, thickness)
{
   p.object.thickness = thickness;
}

define xfig_plot_set_line_depth (p, depth)
{
   p.object.line_depth = depth;
}
define xfig_plot_set_axis_depth (p, depth)
{
   p.object.axis_depth = depth;
}
define xfig_plot_set_point_depth (p, depth)
{
   p.object.point_depth = depth;
}
define xfig_plot_inc_line_depth (p, depth)
{
   p.object.line_depth += depth;
}
define xfig_plot_inc_axis_depth (p, depth)
{
   p.object.axis_depth += depth;
}
define xfig_plot_inc_point_depth (p, depth)
{
   p.object.point_depth += depth;
}
define xfig_plot_get_line_depth (p, depth)
{
   return p.object.line_depth;
}
define xfig_plot_get_axis_depth (p, depth)
{
   return p.object.axis_depth;
}
define xfig_plot_get_point_depth (p, depth)
{
   return p.object.point_depth;
}

define xfig_plot_inc_image_depth (p, depth)
{
   p.object.image_depth += depth;
}
define xfig_plot_get_image_depth (p, depth)
{
   return p.object.image_depth;
}
define xfig_plot_set_image_depth (p, depth)
{
   p.object.image_depth = depth;
}


define xfig_plot_set_point_size (p, point_size)
{
   if (point_size < 0)
     point_size = 0;
   p.object.point_size = point_size;
}
define xfig_plot_set_point_color (p, color)
{
   p.object.point_color = color;
}


%!%+
%\function{xfig_plot_add_object}
%\synopsis{Add an object to a plot at a world coordinate position}
%\usage{xfig_plot_add_object (plot_win, obj [,x,y [,dx,dy]])}
%\description
%  This function may be used to add an object to a plot window at a specified
%  world coordinate.  The \exmp{dx} and \exmp{dy} arguments control the 
%  justification of the object.  The values of these parameters are offsets
%  relative to the size of the object, and as such ordinarily have values 
%  in the interval \exmp{[-0.5,0.5]}.  For example, \exmp{0,0} will center
%  the object on \exmp{(x,y)}, and \exmp{(-0.5,-0.5)} will move the lower left
%  corner of the object to the specified coordinate.
%\seealso{xfig_plot_define_world1}
%!%-
define xfig_plot_add_object ()
{
   variable p, obj, x=NULL, y=NULL, dx=0, dy=0;
   switch (_NARGS)
     {
      case 6:
	(x,y,dx,dy) = ();
     }
     {
      case 4:
	(x,y) = ();
     }
     {
	if (_NARGS != 2)
	  usage ("%s(plot_win, obj [x, y [, dx, dy]])", _function_name);
     }
   (p, obj) = ();
	
   p = p.object;

   if ((x != NULL) and (y != NULL))
     {
	x = scale_coords_for_axis (p.x1axis, p.plot_width, x);
	y = scale_coords_for_axis (p.y1axis, p.plot_height, y);
	
	xfig_justify_object (obj, p.X + vector (x,y,0), vector(dx, dy, 0));
     }

   xfig_compound_list_insert (p.object_list, obj);
}


%!%+
%\function{xfig_plot_text}
%\synopsis{Add text to the plot}
%\usage{xfig_plot_text (w, text, x, y [,dx, dy])}
%#v+
%        w: plot object
%     x, y: world coordinates
%   dx, dy: justification
%#v-
%\description
%  This function creates a text object at the specified location on the plot.
%  By default, the text will be centered on the specified world coordinates.
%  The justification parameters \exmp{dx} and \exmp{dy} may be used to specify
%  the justifcation of the text.  See the documentation for \sfun{xfig_plot_add_object}
%  for more information.
%\example
%#v+
%   xfig_plot_text (w, "$cos(\omega t)$"R, 3.2, 6.0, -0.5, 0);
%#v-
% will left justify the text at the position (3.2,6.0).
%\seealso{xfig_plot_add_object, xfig_new_text}
%!%-
define xfig_plot_text ()
{
   variable w, text, x, y, dx = 0, dy = 0;
   if (_NARGS == 6)
     (dx, dy) = ();
   else if (_NARGS != 4)
     usage ("%s (win, text, x, y [dx, dy])", _function_name);
   (w, text, x, y) = ();
   
   text = xfig_new_text (text);
   xfig_plot_add_object (w, text, x, y, dx, dy);
}


%!%+
%\function{xfig_plot_title}
%\synopsis{Add a title to a plot}
%\usage{xfig_plot_title (w, title)}
%!%-
define xfig_plot_title ()
{
   variable w, title;
   (w, title) = ();

   variable x0, x1, y, z;
   (,,,y,,z) = xfig_get_object_bbox (w);

   variable p = w.object;
   x0 = p.X.x;
   x1 = x0 + p.plot_width;

   if (typeof (title) == String_Type)
     title = xfig_new_text (title);
   xfig_justify_object (title, vector(0.5*(x0+x1), y, z), vector(0,-1,0));
   xfig_plot_add_object (w, title);
}

private define add_pict_to_plot (w, png)
{
   variable dx, dy;
   (dx, dy) = xfig_get_pict_bbox (png);
   variable p = w.object;
   variable width = p.plot_width;
   variable height = p.plot_height;
   xfig_scale_pict (png, width/dx, height/dy);

   xfig_center_pict_in_box (png, p.X + 0.5*vector (width,height,0), width, height);
   xfig_plot_add_object (w, png);
   xfig_set_depth (png, p.image_depth);
}


%!%+
%\function{xfig_plot_png}
%\synopsis{Add a png file to a plot, scaling it to the window}
%\usage{xfig_plot_png (w, file)}
%!%-
define xfig_plot_png (w, png)
{
   png = xfig_new_png (png);
   add_pict_to_plot (w, png);
}



%!%+
%\function{xfig_plot_new_png}
%\synopsis{Create a new plot window for a png file}
%\usage{w = xfig_plot_new_png (file)}
%!%-
define xfig_plot_new_png (png)
{
   png = xfig_new_png (png);
   variable dx, dy;
   (dx, dy) = xfig_get_pict_bbox (png);
   variable w = xfig_plot_new (dx, dy);
   add_pict_to_plot (w, png);
   return w;
}

private define ones()
{
   !if (_NARGS) return 1;
   variable a = __pop_args (_NARGS);
   return 1 + Int_Type[__push_args (a)];
}


%!%+
%\function{xfig_meshgrid}
%\synopsis{Produce grid points for an image}
%\usage{(xx,yy) = xfig_meshgrid (xx, yy)}
%\description
% This function takes two 1-d vectors representing the orthogonal
% grids for a rectangular region in the (x,y) plane and returns two
% 2-d arrays corresponding to the (x,y) coordinates of each
% intersecting grid point.  
% 
% Suppose that one wants to evaluate a
% function \exmp{f(x,y)} at each point defined by the two grid
% vectors.  Simply calling \exmp{f(x,y)} using the grid vectors would
% lead to either a type-mismatch error or produce a 1-d result.  The
% correct way to do this is to use the \sfun{xfig_meshgrid} function:
%#v+
%    result = f(xfig_meshgrid(x,y));
%#v-
%!%-
define xfig_meshgrid ()
{
   variable x,y;

   if (_NARGS != 2)
     usage ("(xx,yy)=xfig_meshgrid (x,y) ==> produces grid vectors for an image");
   
   (x,y) = ();
   
   variable nx, ny, xx, yy, i;
   nx = length (x);
   ny = length (y);

   xx = x # ones(1,ny);
   yy = ones(nx) # transpose(y);

   return xx, yy;
}
