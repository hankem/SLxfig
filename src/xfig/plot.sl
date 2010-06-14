% -*- mode: slang; mode: fold; -*-
private variable DEFAULT_IMAGE_DEPTH = 89;
private variable DEFAULT_TIC_DEPTH = DEFAULT_IMAGE_DEPTH-10;
private variable DEFAULT_LINE_DEPTH = DEFAULT_TIC_DEPTH-10;
private variable DEFAULT_POINT_DEPTH = DEFAULT_LINE_DEPTH-10;
private variable DEFAULT_FRAME_DEPTH = DEFAULT_POINT_DEPTH-10;

private variable ERRBAR_TERMINAL_SIZE = 0.1;

% convert a scalar to an array of size n
private define convert_to_array (s, n) %{{{
{
   variable type = typeof (s);
   if (type == Array_Type)
     return s;

   variable a = type[n];
   a[*] = s;
   return a;
}
%}}}

define xfig_new_legend (labels, colors, linestyles, thicknesses, width) %{{{
%!%+
%\function{xfig_new_legend}
%\synopsis{Create a plot legend object}
%\usage{legend = xfig_new_legend (labels[], colors[], linestyles[], thicknesses[], width);}
%\qualifiers
%\qualifier{areafill=intval}{}{20}
%\qualifier{fillcolor=strval}{}{"white"}
%\description
%  The \sfun{xfig_new_legend} function creates a legend object suitable for adding
%  to a plot.  The legend will consist of ...
%!%-
% FIXME: allow any object, not just a line...
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
	legend.insert (obj);

	(,,y0,y1,,) = obj.get_bbox ();
	y = 0.5*(y0+y1);
	obj = xfig_new_polyline (vector([0,width], [y,y], [0,0]));
	obj.set_pen_color (colors[i]);
	obj.set_thickness (thicknesses[i]);
	obj.set_line_style (linestyles[i]);
	legend.insert (obj);

	y = y0 - 0.1 * (y1-y0);
     }

   (x0, x1, y0, y1,,) = legend.get_bbox ();
   variable border = (0.5 * (y1-y0))/num;
   legend.translate (vector (border-x0, border-y0, 0));
   variable box = xfig_new_rectangle ((x1-x0)+2*border, (y1-y0)+2*border);

   box.set_area_fill (qualifier("areafill", 20));
   box.set_fill_color (qualifier("fillcolor", "white"));

   legend.insert (box);
   return legend;
}
%}}}

%{{{ Plot_Axis_Type, etc

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
   xmin = 0.1, xmax = 1.0,
   wcs_transform,
   islog = 0, 			       %  if non-zero, is a log axis.  if < 0 format tics as non-log
   major_tics, minor_tics, maxtics,
   user_specified_major_tics, user_specified_minor_tics,
   user_specified_tic_labels,
   %tic_label_format, tic_labels, tic_labels_dX,   %  from tic
   tic_label_format, tic_label_strings, tic_labels_font_struct = xfig_make_font (),
   tic_label_objects,
   tic_labels_tweak, % from tic
   tic_labels_just,    % justification for tic labels and axis_label
   max_tic_h=0.0, max_tic_w=0.0,	       % max width and height of tic label bbox
   geom,			       %  geometric parameters
   line, major_tic_marks, minor_tic_marks,
   minor_tic_len = 0.15,
   major_tic_len = 0.25,
   major_tic_color = "black",
   minor_tic_color = "black",
   major_tic_linestyle = 0,
   minor_tic_linestyle = 0,
   major_tic_thickness = 1,
   minor_tic_thickness = 1,
   axis_color = "black",
   axis_linestyle = 0,
   axis_thickness = 1,
   axis_label, axis_label_rotated = 0,

   draw_line=1, draw_major_tics=1, draw_minor_tics=1, draw_tic_labels=1,
   inited = 0,
   needs_setup = 1,
   axis_depth = DEFAULT_FRAME_DEPTH,
   tic_depth = DEFAULT_TIC_DEPTH,
};

private variable XFig_Plot_Legend_Type = struct
{
   X, width,
   names, objects
};

private variable XFig_Plot_Data_Type = struct
{
   X,
   plot_width, plot_height,	       %  plot window, does not include labels
   x1axis, y1axis, x2axis, y2axis,   %  Plot_Axis_Type
   world1_inited = 0, world2_inited = 0,
   line_color, line_style, thickness,
   point_color, point_size,
   object_list,
   title_object,
   num_plots = 0,

   % methods
   line_depth, point_depth, axis_depth, image_depth,
   legend
};

%}}}

%{{{ Coordinate transforms: linear, log, etc

private variable WCS_Transforms = Assoc_Type[];
private define setup_axis_wcs (axis, wcs_type)
{
   if (0 == assoc_key_exists (WCS_Transforms, wcs_type))
     {
	vmessage ("*** Warning: axis transform %s not supported.  Using linear", wcs_type);
	wcs_type = "linear";
     }
   axis.islog = (wcs_type == "log");
   variable wcs = WCS_Transforms[wcs_type];
   axis.wcs_transform = wcs;
   variable wcs_xmin = wcs.xmin;  if (wcs_xmin == NULL) wcs_xmin = -_Inf;
   variable wcs_xmax = wcs.xmax;  if (wcs_xmax == NULL) wcs_xmax = _Inf;

   variable x = axis.xmin;
   if (x == NULL)
     x = 0.1;
   if (0 == (wcs_xmin <= x < wcs_xmax))
     x = wcs_xmin;
   axis.xmin = x;

   x = axis.xmax;
   if (x == NULL)
     x = 1.0;
   if (0 == (wcs_xmin < x <= wcs_xmax))
     x = wcs_xmax;
   axis.xmax = x;
}

private define world_to_normalized (wcs, x, x0, x1)
{
   variable cd = wcs.client_data;
   variable f = wcs.wcs_func;
   variable t0 = (@f)(double(x0), cd);
   variable t1 = (@f)(double(x1), cd);
   return ((@f)(double(x), cd) - t0)/(t1-t0);
}

private define normalized_to_world (wcs, t, x0, x1)
{
   variable cd = wcs.client_data;
   variable f = wcs.wcs_func;
   variable t0 = (@f)(double(x0), cd);
   variable t1 = (@f)(double(x1), cd);

   variable x = t0 + t*(t1-t0);
   return (@wcs.wcs_invfunc)(t0 + t*(t1-t0), cd);
}

private define round_generic_tic (x)
{
   % Try to choose tics that end in 0 or 5
   variable y = x mod 10;
   x -= y;
   if (2.5 <= y <= 7.5)
     return x + 5;
   if (y < 2.5)
     return x;
   return x + 10;
}

private define generic_compute_tics (wcs, xmin, xmax, ntics)
{
   ifnot (ntics mod 2) ntics--;
   variable c = [0:1:#ntics];
   variable dc = (c[1] - c[0])*0.75;
   variable tics = normalized_to_world (wcs, c, xmin, xmax);
   variable s = sign(tics);
   tics *= s;

   % x = a*10^b
   % log10(x) = log10(a) + b
   variable bad = where (tics <= 0);
   variable y = log10(tics);
   variable b = int(y);
   variable a = y - b;
   variable i = where (a < 0);
   a[i] += 1;
   b[i] -= 1;
   a[bad] = 0;
   b[bad] = 0;
   a = 10.0^a;

   tics = a * 10^b;
   variable n = length (tics);
   variable ok = Char_Type[n];
   loop (5)
     {
	_for i (0, n-1, 1)
	  {
	     if (ok[i])
	       continue;

	     variable a_i = a[i];
	     variable b_i = 10^b[i];
	     variable c_i = c[i];
	     variable dc1, dc2, tic_1, tic_2;
	     tic_1 = round_generic_tic (a_i) * b_i;
	     if (xmin <= tic_1 <= xmax)
	       {
		  dc1 = abs(c_i-world_to_normalized (wcs, s[i]*tic_1, xmin, xmax));
		  if (dc1 < dc)
		    {
		       tics[i] = tic_1;
		       ok[i] = 1;
		       continue;
		    }
	       }
	     tic_1 = int(a_i)*b_i;
	     tic_2 = nint(a_i)*b_i;
	     dc1 = abs(c_i-world_to_normalized (wcs, s[i]*tic_1, xmin, xmax));
	     dc2 = abs(c_i-world_to_normalized (wcs, s[i]*tic_2, xmin, xmax));
	     if (dc1 < dc2)
	       {
		  if (dc1 < dc)
		    {
		       tics[i] = tic_1;
		       ok[i] = 1;
		       continue;
		    }
	       }
	     else
	       {
		  if (dc2 < dc)
		    {
		       tics[i] = tic_2;
		       ok[i] = 1;
		       continue;
		    }
	       }

	     a[i] = a_i*10;
	     b[i]--;
	  }
	if (all(ok))
	  break;
     }

   tics = s*tics;
   variable t0 = tics[0];
   variable j = 0;
   i = 1;
   while (i < n)
     {
	variable t1 = tics[i];
	i++;
	if (t1 == t0)
	  continue;
	j++;
	tics[j] = t1;
	t0 = t1;
     }
   tics = tics[[0:j]];
   n = length(tics);
   if (n <= 1)
     return NULL, NULL;

   t0 = tics[0];
   t1 = tics[-1];
   if (t0 < 0.0 < t1)
     tics[wherefirst (minabs(tics) == abs(tics))] = 0;

   return tics, NULL;
}

private define wcs_compute_major_minor_tics (wcs, xmin, xmax, maxtics)
{
   variable f = wcs.compute_major_minor_tics;
   if (f == NULL)
     return NULL, NULL;

   if (f == &generic_compute_tics)
     return (@f)(wcs, xmin, xmax, maxtics);

   return (@f)(xmin, xmax, maxtics, wcs.client_data);
}

define xfig_plot_add_transform (name, wcs_func, wcs_invfunc, client_data)
%!%+
%\function{xfig_plot_add_transform}
%\usage{xfig_plot_add_transform (String_Type name, Ref_Type &wcs_func, &wcs_invfunc, Any_Type client_data);}
%\qualifiers
%\qualifier{xmin}{}{-inf}
%\qualifier{xmax}{}{+inf}
%\qualifier{ticfun}{}{&generic_compute_tics}
%\description
%  \exmp{wcs_func} (\exmp{wcs_invfunc}) is a function
%  of two arguments: the world (plot) coordinate and some client data.
%  It has to return the correspondig plot (world) coordinate.
%
%  The qualifier \exmp{ticfun} may reference a function
%  that takes 4 arguments: xmin, xmax, maxtics, and client_data.
%  It is supposed to return two arrays of major and minor tic marks.
%!%-
{
   variable s = struct
     {
	wcs_func = wcs_func,
	wcs_invfunc = wcs_invfunc,
	client_data = client_data,
	xmin = qualifier ("xmin", -_Inf),
	xmax = qualifier ("xmax", _Inf),
	compute_major_minor_tics = qualifier("ticfun"),
     };

   if ((s.compute_major_minor_tics == NULL)
       && (name != "log") && (name != "linear"))
     s.compute_major_minor_tics = &generic_compute_tics;

   WCS_Transforms[name] = s;
}

private define linear_wcs_func (x, cd)
{
   return x;
}
xfig_plot_add_transform ("linear", &linear_wcs_func, &linear_wcs_func, NULL);

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

private define log_wcs_func (x, cd)
{
   return log10 (x);
}
private define log_wcs_invfunc (x, cd)
{
   return 10.0^x;
}

xfig_plot_add_transform ("log", &log_wcs_func, &log_wcs_invfunc, NULL;
			 xmin = DOUBLE_MIN);

private define sqrt_wcs_func (x, cd)
{
   return sqrt (x);
}
private define sqrt_wcs_invfunc (x, cd)
{
   return x*x;
}

xfig_plot_add_transform ("sqrt", &sqrt_wcs_func, &sqrt_wcs_invfunc, NULL;
			 xmin = 0);

private define cdf_tan_wcs_func (x, theta0)
{
   return 0.5 * (1.0 + tan((2.0*x-1.0)*theta0)/tan(theta0));

  % (1 + tan((2x-1)*t0)/tan(t0)/2;
  % 2*x-1 = tan((2x-1)*t0)/tan(t0)

}
private define cdf_tan_wcs_invfunc (x, theta0)
{
   return 0.5*(1.0 + atan((2.0*x-1.0)*tan(theta0))/theta0);
}

private define cdf_compute_tics (xmin, xmax, maxtics, cd)
{
   variable major = [0, 0.01, 0.05, 0.1, 0.2, 0.5, 0.8, 0.9, 0.95, 0.99, 1.0];
   variable minor =  [[0:0.1:0.01], [0.1:0.9:0.1], [0.9:1.0:0.01]];
   if (length (where (xmin <= major <= xmax)) < 2)
     return NULL, NULL;

   return major, minor;
}

xfig_plot_add_transform ("cdf", &cdf_tan_wcs_func, &cdf_tan_wcs_invfunc, PI/2-0.15
			 ;ticfun=&cdf_compute_tics,
			 xmin = 0, xmax = 1);

% x >= 1:  y = 2 - 1/x^n  ==> y >= 1
% x <  1:  y = x^n        ==> y < 1
private define resid_wcs_func (x, n)
{
   variable s = sign(x);
   x = s*x;
   variable y = Double_Type[length(x)];
   variable i, j;
   i = where (x >= 1, &j);
   y[i] = 2.0 - 1.0/(x[i]^n);
   y[j] = x[j]^n;
   if (typeof (x) != Array_Type)
     y = y[0];
   return y*s;
}

private define resid_wcs_invfunc (y, n)
{
   variable x = Double_Type[length(y)];
   variable i, j;
   variable s = sign(y);
   y = s*y;
   i = where (y >= 1.0, &j);
   x[i] = (1.0/(2.0 - y[i]))^(1.0/n);
   x[j] = y[j]^(1.0/n);
   if (typeof (y) != Array_Type)
     x = x[0];
   return x*s;
}
xfig_plot_add_transform ("resid", &resid_wcs_func, &resid_wcs_invfunc, 2.0);

%}}}

private define compute_major_tics (xmin, xmax, maxtics, tic_intervals) %{{{
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

%}}}

private define get_major_tics (xmin, xmax, islog, maxtics) %{{{
{
   variable tic_intervals = [1.0,2.0,5.0];
   % 1, 1.2,1.4,1.6,1.8, 2
   % 2, 3.0, 4
   % 5, 6.0,7.0,8.0,9.0, 10, ...
   variable num_minor = [4, 1, 4];
   variable ti, n;

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

	num_minor = [0:5];
	tic_intervals = num_minor+1.0;
	if ((xmax - xmin + 1) <= maxtics)
	  {
	     num_minor = 0;
	     tic_intervals = [1.0];
	  }
     }

   (ti, n) = compute_major_tics (xmin, xmax, maxtics, tic_intervals);
   if (islog)
     {
	% For a log axis, only integer valued major tics are meaningful
	ti = ti[where (feqs (ti, int(ti)))];
     }

   return ti, num_minor[n];
}

%}}}

private define make_tic_objects (axis, tics, X, xmin, xmax, dX, dY, ticlen) %{{{
{
   xmin = double(xmin);
   xmax = double(xmax);
   variable den = (xmax - xmin);
   variable list = xfig_new_polyline_list ();

   variable f = axis.wcs_transform.wcs_func;
   variable cd = axis.wcs_transform.client_data;
   variable t0 = (@f)(xmin, cd);
   variable t1 = (@f)(xmax, cd);
   variable dt = t1 - t0;

   dY = vector_mul (ticlen, dY);
   variable Xmax = vector_sum (X, dX);

   _for (0, length(tics)-1, 1)
     {
	variable i = ();

	variable x = ((@f)(double(tics[i]), cd) - t0)/dt;

	variable X0 = vector_sum (X, vector_mul(x, dX));
	variable X1 = vector_sum (X0, dY);

	list.insert (vector ([X0.x, X1.x],
			     [X0.y, X1.y],
			     [X0.z, X1.z]));
     }
   return list;
}
%}}}

private define make_tic_marks (axis) %{{{
{
   if (axis == NULL)
     return;

   variable X = axis.X, dX = axis.dX, dY = axis.dY;
   variable xmin = axis.xmin;
   variable xmax = axis.xmax;

   variable islog = axis.islog;

   variable X1 = vector_sum (X, dX);
   if (axis.draw_line)
     {
	variable line = xfig_new_polyline (vector ([X.x, X1.x],[X.y,X1.y],[X.z,X1.z]));
	line.set_pen_color (axis.axis_color);
	line.set_line_style (axis.axis_linestyle);
	line.set_thickness (axis.axis_thickness);
	line.set_depth (axis.axis_depth);

	axis.line = line;
     }

   axis.minor_tic_marks = NULL;
   axis.major_tic_marks = NULL;

   variable ticlen;
   variable tics;
   tics = axis.major_tics;

   if ((tics != NULL) && axis.draw_major_tics)
     {
	tics = make_tic_objects (axis, tics, X, xmin, xmax, dX, dY,
				 axis.major_tic_len);
	tics.set_pen_color (axis.major_tic_color);
	tics.set_line_style (axis.major_tic_linestyle);
	tics.set_thickness (axis.major_tic_thickness);
	tics.set_depth (axis.tic_depth);
	axis.major_tic_marks = tics;
     }

   tics = axis.minor_tics;
   if ((tics != NULL) && (axis.draw_minor_tics))
     {
	tics = make_tic_objects (axis, tics, X, xmin, xmax, dX, dY,
				 axis.minor_tic_len);
	tics.set_pen_color (axis.minor_tic_color);
	tics.set_line_style (axis.minor_tic_linestyle);
	tics.set_thickness (axis.minor_tic_thickness);
	tics.set_depth (axis.tic_depth);
	axis.minor_tic_marks = tics;
     }
}
%}}}

private define format_labels_using_scientific_notation (tics) %{{{
{
   variable log10_tics = log10 (abs(tics));
   % x = a*10^b ==> log10(x) = log10(a) + b;
   %                         = log10(10a) + (b-1)
   variable b = int (log10_tics);
   variable a = log10_tics - b;
   variable j = where (a < 0.0); a[j] += 1; b[j] -= 1;
   a = nint(10^a);
   j = where (a == 10); a[j] = 1; b[j] += 1;
   a[where(tics<0)] *= -1;
   return array_map (String_Type, &sprintf, "$\bm%g{\times}10^{%d}$"R, a, b);
}
%}}}

private define construct_tic_label_strings (axis, tics); %{{{
private define construct_tic_label_strings (axis, tics)
{
   if (axis.user_specified_tic_labels != NULL)
     {
	if (_typeof(axis.user_specified_tic_labels) == String_Type)
	  return axis.user_specified_tic_labels;

	tics = axis.user_specified_tic_labels;
     }

   variable format = axis.tic_label_format;
   variable fixed_format = (format != NULL);
   variable i, j, alt_fmt = NULL;
   variable tic_labels;
   variable a, b;
   if (axis.islog > 0)
     {
	if (format == NULL)
	  {
	     format = "\\bf 10$\\bm^{%g}$";
	     alt_fmt = "\\bf %.5g";
	  }
	variable log10_tics = log10 (tics);
	variable frac, whole;
	variable is_frac = fneqs (log10_tics, nint(log10_tics));
	frac = where (is_frac, &whole);
	tic_labels = String_Type[length(tics)];
	tic_labels[whole] = array_map (String_Type, &sprintf, format, log10_tics[whole]);

	variable is_small = (0.01 <= tics < 99999.5);
	ifnot (fixed_format)
	  {
	     if (all(is_small))
	       tic_labels = array_map (String_Type, &sprintf, alt_fmt, tics);
	     else
	       {
		  i = where (is_small and not is_frac);
		  tic_labels[i] = array_map (String_Type, &sprintf, alt_fmt, tics[i]);

		  if ((length(whole) <= 1) && any(is_frac))
		    {
		       i = where (is_small and is_frac);
		       tic_labels[i] = array_map (String_Type, &sprintf, alt_fmt, tics[i]);

		       i = where (is_frac and (not is_small));
		       tic_labels[i] = format_labels_using_scientific_notation (tics[i]);
		    }
	       }
	  }
     }
   else
     {
	if (format == NULL)
	  format = "\\bf %.5g";

	tic_labels = array_map (String_Type, &sprintf, format, tics);
	ifnot (fixed_format)
	  {
	     variable abs_tics = abs(tics);
	     % 1.5e-4 = 0.00015
	     %        = 1.5*10-4
	     %        > 0.00001
	     i = where (((abs_tics > 0) and (abs_tics < 1e-4))
		   or (abs_tics >= 99999.5));
	     if (length(i))
	       tic_labels[i] = format_labels_using_scientific_notation (tics[i]);
	  }
     }
   return tic_labels;
}
%}}}

private define position_tic_label_objects (axis, tic_pos, tic_label_objects) %{{{
{
   ifnot (axis.draw_tic_labels)
     return;

   variable X = axis.X, dX = axis.dX;
   variable xmin = double(axis.xmin);
   variable xmax = double(axis.xmax);

   variable f = axis.wcs_transform.wcs_func;
   variable cd = axis.wcs_transform.client_data;
   variable t0 = (@f)(double(xmin), cd);
   variable t1 = (@f)(double(xmax), cd);
   variable dt = t1 - t0;

   variable Xmax = vector_sum (X, dX);
   _for (0, length(tic_label_objects)-1, 1)
     {
	variable i = ();
	variable x = tic_pos[i];

	x = ((@f)(double(x), cd) - t0)/dt;

	variable X0 = vector_sum (X, vector_mul(x, dX));

	xfig_justify_object (tic_label_objects[i], X0 + axis.tic_labels_tweak, axis.tic_labels_just);
	if (dX.y != 0)
	  {
	     % y tic
	     variable y0, y1, dy = 0;
	     (,,y0,y1,,) = tic_label_objects[i].get_bbox();
	     if (y1 > Xmax.y)
	       dy = Xmax.y - y1;
	     if (y0 < X.y)
	       dy = X.y - y0;
	     if (dy != 0)
	       tic_label_objects[i].translate (vector (0,dy,0));
	  }
     }

   % Convert the tic labels to a compound object for ease of manipulation
   variable compound = xfig_new_compound_list ();
   foreach (axis.tic_label_objects)
     {
	variable label = ();
	compound.insert(label);
     }
   axis.tic_label_objects = compound;
}
%}}}

private define make_tic_label_objects (axis, tic_labels_just, tweakx, tweaky) %{{{
{
   variable major_tics = axis.major_tics;
   variable tics = major_tics;
   variable max_tic_h = 0, max_tic_w = 0;
   variable num_tics = length (tics);

   if ((tics == NULL) || (num_tics == 0) || (axis.draw_tic_labels == 0))
     {
	axis.tic_label_objects = NULL;
	return;
     }

   if (axis.islog && (1 <= num_tics <= 2))
     {
	variable major_tic = major_tics[0];
	variable new_tics = [major_tic/5.0,major_tic/2.0, major_tic*2.0,major_tic*5.0];
	if (num_tics == 2)
	  {
	     major_tic = major_tics[1];
	     new_tics = [new_tics, major_tic*2,major_tic*5];
	  }
	new_tics = new_tics[where (axis.xmin <= new_tics <= axis.xmax)];
	tics = [tics, new_tics];
     }
   variable tic_label_strings = construct_tic_label_strings (axis, tics);
   variable i = wherenot (_isnull (tic_label_strings));
   tic_label_strings = tic_label_strings[i];
   tics = tics[i];

   variable tic_label_objects
     = array_map (Struct_Type, &xfig_new_text, tic_label_strings, axis.tic_labels_font_struct);

   variable tic_labels_dX = Struct_Type[length(tic_label_objects)];
   foreach (tic_label_objects)
     {
	variable obj = ();
	variable w, h;
	(w,h) = obj.get_pict_bbox ();
	if (max_tic_w < w)
	  max_tic_w = w;
	if (max_tic_h < h)
	  max_tic_h = h;
     }

   axis.max_tic_h = max_tic_h + 2*abs(tweaky);
   axis.max_tic_w = max_tic_w + 2*abs(tweakx);
   axis.tic_labels_tweak = vector (tweakx, tweaky, 0);
   axis.tic_labels_just = tic_labels_just;
   axis.tic_label_objects = tic_label_objects;
   axis.tic_label_strings = tic_label_strings;

   position_tic_label_objects (axis, tics, tic_label_objects);
}

%}}}

private define make_major_minor_tic_positions (axis, major_tics, minor_tics) %{{{
{
   variable xmin = axis.xmin;
   variable xmax = axis.xmax;

   if (xmax < xmin)
     (xmin, xmax) = (xmax, xmin);

   if (major_tics == NULL) major_tics = axis.user_specified_major_tics;
   if (minor_tics == NULL) minor_tics = axis.user_specified_minor_tics;

   if (major_tics == NULL)
     {
	(major_tics, minor_tics) = wcs_compute_major_minor_tics (axis.wcs_transform, xmin, xmax, axis.maxtics);
     }

   variable i, j;

   if (major_tics != NULL)
     {
	i = where (xmin <= major_tics <= xmax);
	axis.major_tics = major_tics[i];
	if (axis.user_specified_tic_labels != NULL)
	  axis.user_specified_tic_labels = axis.user_specified_tic_labels[i];
	if (minor_tics != NULL)
	  minor_tics = minor_tics[where (xmin <= minor_tics <= xmax)];
	axis.minor_tics = minor_tics;

	if (length(major_tics) > 1)
	  return;
	major_tics = NULL;
	minor_tics = NULL;
     }

   variable islog = axis.islog;
   variable num_minor, num_major;
   if (islog)
     {
	(xmin, xmax) = check_xmin_xmax_for_log (xmin, xmax);
     }

   (major_tics, num_minor) = get_major_tics (xmin, xmax, islog, axis.maxtics);

   if (islog)
     {
	num_major = length (where (log10(xmin) <= major_tics <= log10(xmax)));
#ifnfalse
	if ((num_major <= 1)
	    %&& (0.001 <= xmin <= xmax <= 100.0)
	    )
	  {
	     % 0 or 1 major tic.  Format as non-log (linear)
	     variable maxtics = (2*axis.maxtics)/3;
	     if (xmax >= 15.0 * xmin)
	       {
		  (major_tics, minor_tics) = generic_compute_tics (WCS_Transforms["log"], xmin, xmax, axis.maxtics);
		  num_minor = (minor_tics == NULL) ? 0 : length (minor_tics);
	       }
	     else
	       (major_tics, num_minor) = get_major_tics (xmin, xmax, 0, maxtics);
	     axis.islog = -1;
	     islog = 0;
	  }
#endif
     }

   variable major_tic_interval = major_tics[1] - major_tics[0];
   variable minor_tic_interval;
   j = [1:num_minor];
   i = j-1;

   if (islog && (num_minor == 0))
      {
	 num_minor = 8;
	 i = [0:num_minor-1];
	 j = log10 ([2:9]);	       %  log10([2:9])
	 minor_tic_interval = 1.0;
      }
   else minor_tic_interval = major_tic_interval/(num_minor+1.0);

   minor_tics = Double_Type[num_minor*length(major_tics)];

   if (num_minor) foreach (major_tics)
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

%}}}

private define setup_axis_tics (p, axis) %{{{
{
   variable geom = axis.geom;

   make_tic_label_objects (axis, axis.tic_labels_just, geom.tic_tweak_x, geom.tic_tweak_y);
   %make_tic_marks_and_tic_labels (axis);
   make_tic_marks (axis);
}

%}}}

% Usage: xfig_plot_set_*_tics (win, major_tics [,tic_labels,[minor_tics]])
% If tic_labels is NULL or not present then they will be generated.
% If tic_labels is "", then none will be generated.

private define pop_set_tic_args (fun, nargs) %{{{
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

%}}}

private define position_axis_label (axis) %{{{
{
   variable label = axis.axis_label;
   if (label == NULL)
     return;

   variable geom = axis.geom;
   variable theta = geom.theta;

   % This routine may have already been called if the label was added
   % before the axis.
   ifnot (axis.axis_label_rotated)
     {
	if (theta != 0) label.rotate_pict (theta);
	axis.axis_label_rotated = 1;
     }

   variable X = 0.5 * (2*axis.X + axis.dX);
   X += vector (geom.tx*axis.max_tic_w, geom.ty*axis.max_tic_h, 0);

   xfig_justify_object (axis.axis_label, X, axis.tic_labels_just);
}
%}}}

private define add_axis_label (p, axis, label) %{{{
{
   if (label == NULL)
     return;

   axis.axis_label = xfig_new_text (label ;; __qualifiers);
   position_axis_label (axis);
}
%}}}

private define add_axis (p, axis, wcs_type, major_tics, minor_tics) %{{{
{
   if (wcs_type != NULL) setup_axis_wcs (axis, wcs_type);
   make_major_minor_tic_positions (axis, major_tics, minor_tics);

   setup_axis_tics (p, axis);

   position_axis_label (axis);
   axis.needs_setup = 0;
}

%}}}

private define render_tics_for_axis (axis, fp) %{{{
{
   if (axis == NULL)
     return;

   if (axis.line != NULL)
     axis.line.render (fp);
   if (axis.major_tic_marks != NULL)
     axis.major_tic_marks.render (fp);
   if (axis.tic_label_objects != NULL)
     axis.tic_label_objects.render (fp);
   if (axis.minor_tic_marks != NULL)
     axis.minor_tic_marks.render (fp);
   if (axis.axis_label != NULL)
     axis.axis_label.render (fp);
   %xfig_render_object (axis.axis_label, fp);
}

%}}}

private define render_plot_axes (p, fp) %{{{
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

%}}}

private define translate_axis (axis, X) %{{{
{
   axis.X = vector_sum (axis.X, X);
   if (axis.line != NULL)
     axis.line.translate(X);
   if (axis.major_tic_marks != NULL)
     axis.major_tic_marks.translate(X);
   if (axis.minor_tic_marks != NULL)
     axis.minor_tic_marks.translate(X);
   if (axis.tic_label_objects != NULL)
     axis.tic_label_objects.translate(X);
   if (axis.axis_label != NULL)
     axis.axis_label.translate(X);
}

%}}}

private define plot_translate (p, X) %{{{
{
   p = p.plot_data;
   p.X = vector_sum (p.X, X);
   translate_axis (p.x1axis, X);
   translate_axis (p.x2axis, X);
   translate_axis (p.y1axis, X);
   translate_axis (p.y2axis, X);
   p.object_list.translate(X);
   if (p.title_object != NULL)
     p.title_object.translate(X);
}

private define rotate_axis (axis, normal, theta)
{
   axis.X = vector_rotate (axis.X, normal, theta);
   if (axis.line != NULL)
     axis.line.rotate(normal, theta);
   if (axis.major_tic_marks != NULL)
     axis.major_tic_marks.rotate(normal, theta);
   if (axis.minor_tic_marks != NULL)
     axis.minor_tic_marks.rotate(normal, theta);
   if (axis.tic_label_objects != NULL)
     axis.tic_label_objects.rotate(normal, theta);
   if (axis.axis_label != NULL)
     axis.axis_label.rotate(normal, theta);
}

%}}}

private define plot_rotate (p, normal, theta) %{{{
{
   p = p.plot_data;
   p.X = vector_rotate (p.X, normal, theta);
   rotate_axis (p.x1axis, normal, theta);
   rotate_axis (p.x2axis, normal, theta);
   rotate_axis (p.y1axis, normal, theta);
   rotate_axis (p.y2axis, normal, theta);
   p.object_list.rotate(normal, theta);
   if (p.title_object != NULL)
     p.title_object.rotate(normal, theta);
}

%}}}

private define plot_scale () %{{{
{
   variable p, sx, sy, sz;
   (p, sx, sy, sz) = _xfig_get_scale_args (_NARGS);

   variable X = p.plot_data.X;
   X.x *= sx;
   X.y *= sy;
   X.z *= sz;
}

%}}}

private define plot_set_attr (p, attr, val)
{
}

private define get_axis_bbox (axis) %{{{
{
   variable x0, x1, y0, y1, z0, z1;
   (x0, x1, y0, y1, z0, z1) = xfig_new_compound (axis.line, axis.tic_label_objects, axis.axis_label).get_bbox ();

   variable X0 = axis.X, X1 = X0+axis.dX;
   variable x = [X0.x, X1.x];
   variable y = [X0.y, X1.y];
   variable z = [X0.z, X1.z];
   return min([x,x0]), max([x,x1]), min([y,y0]), max([y,y1]), min([z,z0]), max([z,z1]);
}
%}}}

private define plot_get_bbox (p) %{{{
{
   if (0) vmessage ("Warning: plot bounding box not fully supported");
   p = p.plot_data;
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
   foreach (p.object_list)
     {
	variable obj = ();
	(x0, x1, y0, y1, z0, z1) = obj.get_bbox ();
	if (x0 < xmin) xmin = x0;
	if (x1 > xmax) xmax = x1;
	if (y0 < ymin) ymin = y0;
	if (y1 > ymax) ymax = y1;
	if (z0 < zmin) zmin = z0;
	if (z1 > zmax) zmax = z1;
     }

   obj = p.title_object;
   if (obj != NULL)
     {
	(x0, x1, y0, y1, z0, z1) = obj.get_bbox ();
	if (x0 < xmin) xmin = x0;
	if (x1 > xmax) xmax = x1;
	if (y0 < ymin) ymin = y0;
	if (y1 > ymax) ymax = y1;
	if (z0 < zmin) zmin = z0;
	if (z1 > zmax) zmax = z1;
     }

   return xmin, xmax, ymin, ymax, zmin, zmax;
}

%}}}

private define plot_render (p, fp) %{{{
{
   p = p.plot_data;
   %variable plot_width = p.plot_width;
   %variable plot_height= p.plot_height;

   p.object_list.render (fp);

   if (p.title_object != NULL)
     p.title_object.render (fp);

   % It looks better when the axes are rendered after the plot object
   render_plot_axes (p, fp);
}

%}}}

% Axes Geometries %{{{
private variable X1_Axis_Geom = struct
{
   ticofs_x = 0.0, ticofs_y = 0.5, tic_tweak_x = 0.0,
   tic_tweak_y = -0.1, tx = 0.0, ty = -1.0, theta = 0.0
};
private variable X2_Axis_Geom = struct
{
   ticofs_x = 0.0, ticofs_y = -0.5, tic_tweak_x = 0.0,
   tic_tweak_y = 0.1, tx = 0.1, ty = 1.0, theta = 0.0
};
private variable Y1_Axis_Geom = struct
{
   ticofs_x = 0.5, ticofs_y = 0.0, tic_tweak_x = -0.1,
   tic_tweak_y = 0.0, tx = -1.0, ty = 0.0, theta = 90.0
};
private variable Y2_Axis_Geom = struct
{
   ticofs_x = -0.5, ticofs_y = 0.0, tic_tweak_x = 0.1,
   tic_tweak_y = 0.0, tx = 1.0, ty = 0.0, theta = -90.0
};
%}}}

private define allocate_axis_type (len, maxtics, has_tic_labels, xpos, ypos, dirx, diry, ticdirx, ticdiry, geom) %{{{
{
   variable a = @Plot_Axis_Type;
   setup_axis_wcs (a, "linear");
   a.maxtics = maxtics;
   a.X = vector (xpos, ypos, 0);
   a.dX = vector (dirx*len, diry*len, 0);
   a.dY = vector (ticdirx, ticdiry,0);
   a.geom = geom;
   a.tic_labels_just = vector (geom.ticofs_x, geom.ticofs_y, 0);
   a.draw_tic_labels = has_tic_labels;
   return a;
}

%}}}

private define get_log_qualifier (name) %{{{
{
   if (0 == qualifier_exists (name))
     return 0;
   variable q = qualifier (name);
   if (q == NULL) return 1;
   return q;
}
%}}}

private define get_log_qualifiers () %{{{
{
   return (get_log_qualifier ("xlog" ;; __qualifiers)
	   || get_log_qualifier ("logx" ;; __qualifiers)
	   || qualifier_exists ("loglog")
	   ,
	   get_log_qualifier ("ylog" ;; __qualifiers)
	   || get_log_qualifier ("logy" ;; __qualifiers)
	   || qualifier_exists ("loglog"));
}
%}}}

private define do_axis_method (name, grid_axis) %{{{
{
   variable p;
   switch (_NARGS-2)
     {
      case 1: p = ();
     }
     {
	_pop_n (_NARGS-2);
	usage (".axis ( [;qualifiers] )\n", +
	       "Qualifiers:\n", +
	       " off, on, color=val, line=val, major=array, minor=array,\n" +
	       " width=val, depth=val, ticlabels=0|1|Array_Type, maxtics=val\n" +
	       " wcs=val, lin, log, format=fmt\n"
	      );
     }

   p = p.plot_data;
   variable axis = get_struct_field (p, name);
   variable q = not qualifier_exists("off");
   if (qualifier_exists("on"))
     q = 1;

   axis.draw_major_tics = q;
   axis.draw_line = q;
   axis.draw_minor_tics = q;
   axis.draw_tic_labels = q;

   variable minor_tics = NULL;
   q = qualifier ("minor");
   if (typeof (q) == Int_Type)
     axis.draw_minor_tics = q;
   else
     {
	minor_tics = q;
	if (minor_tics != NULL)
	  axis.user_specified_minor_tics = minor_tics;
     }

   variable major_tics = NULL;
   q = qualifier ("major");
   if (typeof (q) == Int_Type)
     axis.draw_major_tics = q;
   else
     {
	major_tics = q;
	if (major_tics != NULL)
	  axis.user_specified_major_tics = major_tics;
     }

   q = qualifier ("color");
   if (q != NULL)
     {
	axis.axis_color = q;
	axis.major_tic_color = q;
	axis.minor_tic_color = q;
     }
   axis.major_tic_color = qualifier ("major_color", axis.major_tic_color);
   axis.minor_tic_color = qualifier ("minor_color", axis.major_tic_color);

   q = qualifier ("width");
   if (q != NULL)
     {
	axis.axis_thickness = q;
	axis.major_tic_thickness = q;
	axis.minor_tic_thickness = q;
     }
   axis.minor_tic_thickness = qualifier ("minor_width", axis.minor_tic_thickness);
   axis.major_tic_thickness = qualifier ("major_width", axis.major_tic_thickness);

   q = qualifier ("line");
   if (q != NULL)
     {
	axis.axis_linestyle = q;
	axis.major_tic_linestyle = q;
	axis.minor_tic_linestyle = q;
     }

   if (grid_axis)
     {
	axis.major_tic_linestyle = qualifier ("major_line", axis.major_tic_linestyle);
	axis.minor_tic_linestyle = qualifier ("minor_line", axis.minor_tic_linestyle);
     }
   axis.major_tic_len = qualifier ("major_len", axis.major_tic_len);
   axis.minor_tic_len = qualifier ("minor_len", axis.minor_tic_len);

   axis.axis_depth = qualifier ("depth", axis.axis_depth);
   axis.tic_depth = qualifier ("tic_depth", axis.tic_depth);
   axis.maxtics = qualifier ("maxtics", axis.maxtics);

   variable f = axis.tic_labels_font_struct;
   f.style = qualifier ("ticlabel_style", f.style);
   f.color = qualifier ("ticlabel_color", f.color);
   f.size = qualifier ("ticlabel_size", f.size);

   % .islog already has a default value.  Don't muck with it unless
   % requested.
   if (qualifier_exists ("linear")) axis.islog = 0;
   if (qualifier_exists ("log")) axis.islog = get_log_qualifier ("log";;__qualifiers);

   if (qualifier_exists ("format"))
     axis.tic_label_format = qualifier ("format");

   q = qualifier ("ticlabels");
   if (typeof (q) == Int_Type)
     axis.draw_tic_labels = q;
   else if ((typeof (q) == Array_Type) 
	    && ((_typeof(q) == String_Type) || __is_numeric(q)))
     {
	if (major_tics == NULL)
	  message("warning: user specified ticlabels, but no major ticmarks  (=> ignoring ticlabels)");
	else if (length(major_tics) != length(q))
	  vmessage("warning: user specified %d major ticmarks, but %d ticlabels  (=> ignoring ticlabels)",
		   length(major_tics), length(q));
	else
	  axis.user_specified_tic_labels = q;
     }

   if (axis.draw_major_tics == 0)
     axis.draw_tic_labels = 0;

   if (grid_axis)
     {
	variable len = p.plot_height;
	if (grid_axis == 2)
	  len = p.plot_width;
	q = qualifier ("grid");
	if (q == 1)
	  {
	     axis.major_tic_len = len;
	     axis.minor_tic_len = len;
	  }
	q = qualifier ("major_grid", qualifier("majorgrid"));
	if (q == 1)
	  axis.major_tic_len = len;
	q = qualifier ("minor_grid", qualifier("minorgrid"));
	if (q == 1)
	  axis.minor_tic_len = len;
     }

   variable wcs = qualifier ("wcs");
   if ((wcs == NULL)
       && ((axis.wcs_transform == NULL) || (axis.islog)))
     {
	wcs = "linear";
	if (axis.islog)
	  wcs = "log";
     }
   axis.inited = 1;
   add_axis (p, axis, wcs, major_tics, minor_tics);
}
%}}}

private define xaxis_method () %{{{
%!%+
%\function{xfig_plot.xaxis}
%\usage{xfig_plot.xaxis([; qualifiers]);}
%\description
%  This method allows for the configuration of both x-axes
%  via qualifiers -- see \sfun{xfig_plot.axis} for further information.
%\seealso{xfig_plot.axis}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.xaxis")) return;
   variable args = __pop_args (_NARGS);
   do_axis_method (__push_args (args), "x1axis", 1 ;; __qualifiers);
   do_axis_method (__push_args (args), "x2axis", 0 ;; __qualifiers);
}
%}}}

private define yaxis_method () %{{{
%!%+
%\function{xfig_plot.yaxis}
%\usage{xfig_plot.yaxis([; qualifiers]);}
%\description
%  This method allows for the configuration of both y-axes
%  via qualifiers -- see \sfun{xfig_plot.axis} for further information.
%\seealso{xfig_plot.axis}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.yaxis")) return;
   variable args = __pop_args (_NARGS);
   do_axis_method (__push_args (args), "y1axis", 2 ;; __qualifiers);
   do_axis_method (__push_args (args), "y2axis", 0 ;; __qualifiers);
}
%}}}

private define x1axis_method () %{{{
%!%+
%\function{xfig_plot.x1axis}
%\usage{xfig_plot.x1axis([; qualifiers]);}
%\description
%  This method allows for the configuration of the first x-axis
%  via qualifiers -- see \sfun{xfig_plot.axis} for further information.
%\seealso{xfig_plot.axis}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.xaxis")) return;
   variable args = __pop_args (_NARGS);
   do_axis_method (__push_args (args), "x1axis", 1 ;; __qualifiers);
}
%}}}

private define x2axis_method () %{{{
%!%+
%\function{xfig_plot.x2axis}
%\usage{xfig_plot.x2axis([; qualifiers]);}
%\description
%  This method allows for the configuration of the second x-axis
%  via qualifiers -- see \sfun{xfig_plot.axis} for further information.
%\seealso{xfig_plot.axis}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.x2axis")) return;
   variable args = __pop_args (_NARGS);
   do_axis_method (__push_args (args), "x2axis", 1 ;; __qualifiers);
}
%}}}

private define y1axis_method () %{{{
%!%+
%\function{xfig_plot.y1axis}
%\usage{xfig_plot.y1axis([; qualifiers]);}
%\description
%  This method allows for the configuration of the first y-axis
%  via qualifiers -- see \sfun{xfig_plot.axis} for further information.
%\seealso{xfig_plot.axis}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.y1axis")) return;
   variable args = __pop_args (_NARGS);
   do_axis_method (__push_args (args), "y1axis", 2 ;; __qualifiers);
}
%}}}

private define y2axis_method () %{{{
%!%+
%\function{xfig_plot.y2axis}
%\usage{xfig_plot.y2axis([; qualifiers]);}
%\description
%  This method allows for the configuration of the second y-axis
%  via qualifiers -- see \sfun{xfig_plot.axis} for further information.
%\seealso{xfig_plot.axis}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.y2axis")) return;
   variable args = __pop_args (_NARGS);
   do_axis_method (__push_args (args), "y2axis", 2 ;; __qualifiers);
}
%}}}

private define axis_method () %{{{
%!%+
%\function{xfig_plot.axis}
%\usage{xfig_plot.axis([; qualifiers]);}
%\qualifiers
%\qualifier{on}{draw axis, major and minor tic marks, as well as tic labels}{on}
%\qualifier{off}{do not draw axis, major nor minor tic marks, nor tic labels}
%\qualifier{linear}{set linear axis scale}
%\qualifier{log}{set logarithmic axis scale}
%\qualifier{major}{draw major tic marks [precedence over on/off] or array of major tic mark values}
%\qualifier{minor}{draw minor tic marks [precedence over on/off] or array of minor tic mark values}
%\qualifier{color}{color of axis, major and minor tic marks}
%\qualifier{major_color}{color of major tic marks [precedence over color]}
%\qualifier{minor_color}{color of minor tic marks [precedence over color]}
%\qualifier{width}{width of axis, major and minor tic marks}
%\qualifier{major_width}{width of major tic marks [precedence over width]}
%\qualifier{minor_width}{width of minor tic marks [precedence over width]}
%\qualifier{line}{line style of axis, major and minor tic marks}
%\qualifier{major_line}{line style of major tic marks [precedence over line]}
%\qualifier{minor_line}{line style of minor tic marks [precedence over line]}
%\qualifier{major_len}{length of the major tic marks}
%\qualifier{minor_len}{length of the minor tic marks}
%\qualifier{grid}{extend major and minor tic marks to a grid}
%\qualifier{major_grid}{extend major tic marks to a grid [precedence over grid]}
%\qualifier{minor_grid}{extend minor tic marks to a grid [precedence over grid]}
%\qualifier{depth}{Xfig depth of the axis}
%\qualifier{tic_depth}{Xfig depth of the ticmarks}
%\qualifier{maxtics}{ maximum number of major tic marks}
%\qualifier{ticlabels}{draw tic labels (requires major tic marks)}
%\qualifier{ticlabel_style}{tic label font style}
%\qualifier{ticlabel_color}{tic label font color}
%\qualifier{ticlabel_size}{tic label font size}
%\qualifier{wcs}{name of a custom world coordinate system transformation}
%\description
%  All axes can be configured with the qualifiers mentioned above.
%\seealso{xfig_plot.xaxis, xfig_plot.x1axis, xfig_plot.x2axis, xfig_plot.yaxis, xfig_plot.y1axis, xfig_plot.y2axis}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.axis")) return;
   variable args = __pop_args (_NARGS);
   xaxis_method (__push_args (args);; __qualifiers);
   yaxis_method (__push_args (args);; __qualifiers);
}
%}}}

private define get_world_min_max (axis, x0, x1, islog, pad) %{{{
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
	     () = fprintf (stderr, "xfig_plot_define_world: invalid world limits: x0=x1=%g\n", x0);
	     x0 = 0.0;
	     x1 = 1.0;
	  }
     }

   if (islog)
     (x0, x1) = check_xmin_xmax_for_log (x0, x1);

   if (pad == 0.0)
     return x0, x1;

   variable save_x0 = x0;
   variable save_x1 = x1;

   if (islog)
     {
	x0 = log10 (x0);
	x1 = log10 (x1);
     }
   variable dx = pad*(x1 - x0);
   x0 -= dx;
   x1 += dx;
   if (islog)
     {
	x0 = 10^x0;
	x1 = 10^x1;
	if (x0 == 0)
	  x0 = save_x0;
	if (isinf(x1))
	  x1 = save_x1;
     }

   variable wcs = axis.wcs_transform;
   if (x0 < wcs.xmin)
     x0 = wcs.xmin;
   if (x1 > wcs.xmax)
     x1 = wcs.xmax;

   return x0, x1;
}

%}}}

private define do_world_method (nth, nargs) %{{{
{
   variable xdata, ydata;
   variable w, x0, x1, y0, y1;
   variable pad = 0.0;

   switch (nargs)
     {
      case 3:
	(w, xdata, ydata) = ();
	x0 = NULL;
	pad = 0.05;
     }
     {
      case 5:
	(w, x0, x1, y0, y1) = ();
     }
     {
	usage (".world ([x0, x1], [y0, y1] ; xlog, ylog, loglog)");
     }

   variable p = w.plot_data;
   variable xaxis = get_struct_field (p, "x${nth}axis"$);
   variable yaxis = get_struct_field (p, "y${nth}axis"$);

   variable xlog, ylog;
   (xlog, ylog) = get_log_qualifiers (;;__qualifiers);
   xlog = xlog or xaxis.islog;
   ylog = ylog or yaxis.islog;

   if (x0 == NULL)
     {
	if (xlog) xdata = xdata[where (xdata>0)];
	if (ylog) ydata = ydata[where (ydata>0)];

	(x0, x1) = (min(xdata), max(xdata));
	(y0, y1) = (min(ydata), max(ydata));
     }

   (x0, x1) = get_world_min_max (xaxis, x0, x1, xlog, qualifier ("padx", pad));
   (y0, y1) = get_world_min_max (yaxis, y0, y1, ylog, qualifier ("pady", pad));

   xaxis.xmin = double(x0); xaxis.xmax = double(x1); xaxis.islog = xlog;
   yaxis.xmin = double(y0); yaxis.xmax = double(y1); yaxis.islog = ylog;

   yaxis.needs_setup = 1;
   xaxis.needs_setup = 1;
   set_struct_field (p, "world${nth}_inited"$, 1);
}

%}}}

private define world1_method () %{{{
%!%+
%\function{xfig_plot.world1}
%\synopsis{define a plot's first world coordinate system}
%\seealso{xfig_plot.world}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.world1")) return;
   return do_world_method (1, _NARGS ;; __qualifiers);
}
%}}}

% This function is not to be called implictly.  Use do_world_method
% instead.
private define world2_method () %{{{
%!%+
%\function{xfig_plot.world2}
%\synopsis{define a plot's second world coordinate system}
%\seealso{xfig_plot.world}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.world2")) return;
   variable w, args;
   args = __pop_args (_NARGS-1);
   w = ();
   w.plot_data.x2axis.draw_tic_labels = 1;
   w.plot_data.y2axis.draw_tic_labels = 1;
   return do_world_method (w, __push_args(args), 2, _NARGS ;; __qualifiers);
}
%}}}

private define world_method () %{{{
%!%+
%\function{xfig_plot.world}
%\synopsis{define a plot's world coordinate system}
%\usage{xfig_plot.world(Double_Type xdata[], ydata[]);
%\altusage{xfig_plot.world(Double_Type x0, x1, y0, y1);}
%}
%\qualifiers
%\qualifier{xlog}{use a logarithmic x-axis}
%\qualifier{ylog}{use a logarithmic y-axis}
%\qualifier{loglog}{use logarithmic axes}
%\qualifier{padx}{fraction of xrange to be padded on both sides}{0.05 or 0}
%\qualifier{pady}{fraction of yrange to be padded on both sides}{0.05 or 0}
%#c \description
%\seealso{xfig_plot.world1, xfig_plot.world2}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.world")) return;
   variable args = __pop_args (_NARGS);
   do_world_method (__push_args (args), 1, _NARGS ;; __qualifiers);
   do_world_method (__push_args (args), 2, _NARGS ;; __qualifiers);
}
%}}}

private define get_world_axes (p) %{{{
%!%+
%\function{xfig_plot--wcs}
%\synopsis{Qualifiers to specify a plot's world coordinate system}
%\qualifiers
%\qualifier{world0}{use device coordinates for x- and y-axes}
%\qualifier{world1}{use first coordinate system for x- and y-axes}
%\qualifier{world2}{use second coordinate system for x- and y-axes}
%\qualifier{world{a}{b}}{use a-th WCS for x-axis and b-th WCS for y-axis, where 0 <= a, b <= 2}
%\description
%  If none of these qualifiers is specified, world1 is assumed.
%
%  Device coordinates (0th WCS) run from 0 to 1 along the corresponding axis.
%
%  The first or second coordinate system (1st or 2nd WCS) can be defined
%  with the .world(1) or .world(2) methods. (If not set before, they are
%  set automatically by some plot functions, see \sfun{xfig_plot--initialize_plot}.)
%
%  The WCS qualifiers apply to the following functions:
%  \sfun{xfig_plot.plot}, \sfun{xfig_plot.hplot}, \sfun{xfig_plot.shade_region},
%  \sfun{xfig_plot.add_object}, \sfun{xfig_plot.xylabel}, \sfun{xfig_plot.xfig_coords}
%\seealso{xfig_plot.world, xfig_plot.world1, xfig_plot.world2, xfig_plot--initialize_plot}
%!%-
{
   variable x_axes = [NULL, p.x1axis, p.x2axis];
   variable y_axes = [NULL, p.y1axis, p.y2axis];
   variable a = 0;
   loop (3)
     {
	variable b = 0;
	loop (3)
	  {
	     if (qualifier_exists ("world${a}${b}"$))
	       return x_axes[a], y_axes[b];
	     b++;
	  }

	if (qualifier_exists ("world${a}"$))
	  return x_axes[a], y_axes[a];

	a++;
     }
   return p.x1axis, p.y1axis;
}
%}}}

private define get_world_for_axis (a)
{
   if (a == NULL)
     return (0.0, 1.0);

   variable x0 = a.xmin, x1 = a.xmax;
   variable wcs = a.wcs_transform;

   if ((wcs.xmin != NULL) && (x0 < wcs.xmin)) x0 = wcs.xmin;
   if ((wcs.xmax != NULL) && (x1 > wcs.xmax)) x1 = wcs.xmax;

   return (x0, x1);
}

private define scale_coords_for_axis (axis, axis_len, x) %{{{
{
   if (axis == NULL)
     {
	%  device coordinate, x runs from 0 to 1
	return double(x*axis_len);
     }
   return axis_len * 
     world_to_normalized (axis.wcs_transform, x, get_world_for_axis (axis));
}

%}}}

private define xfig_coords_method(p, x, y) %{{{
%!%+
%\function{xfig_plot.xfig_coords}
%\usage{(Double_Type xXfig, yXfig) = xfig_plot.xfig_coords(Double_Type x, y);
%\altusage{Double_Type xXfig = xfig_plot.xfig_coords(Double_Type x, );}
%\altusage{Double_Type yXfig = xfig_plot.xfig_coords(, Double_Type y);}
%}
%\qualifiers
% % qualifiers to specify the world coordinate system,
%\seealso{xfig_plot--wcs}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.xfig_coords")) return;
   p = p.plot_data;
   variable ax, ay;
   (ax, ay) = get_world_axes (p;; __qualifiers);
   if(y!=NULL)  p.X.y + scale_coords_for_axis (ay, p.plot_height, y);  % left on stack
   if(x!=NULL)  p.X.x + scale_coords_for_axis (ax, p.plot_width,  x);  % left on stack
}
%}}}

private define make_nsided_polygon (n, x0, y0, radius) %{{{
{
   variable theta = [0:n]*(2*PI/n); theta = [theta, 0];
   variable x = x0 + radius * cos (theta);
   variable y = y0 + radius * sin (theta);
   return x, y;
}
%}}}

private define plot_lines (p, x, y) %{{{
{
   p = p.plot_data;
   variable ax, ay;
   (ax, ay) = get_world_axes (p ;; __qualifiers);
   variable w = p.plot_width, h = p.plot_height;

   if (length (x) < 2)
     return;

   x = scale_coords_for_axis (ax, w, x);
   y = scale_coords_for_axis (ay, h, y);
   variable bad = Int_Type [length(x)+1];
   bad[-1] = 1;

   variable i = where (isnan (x) or isnan (y));
   bad[i] = 1;

   variable depth = qualifier ("depth", p.line_depth);
   variable thickness = qualifier ("width", p.thickness);
   variable color = qualifier ("color", p.line_color);
   variable linestyle = qualifier ("line", p.line_style);
   variable i0 = 0;
   variable list = xfig_new_polyline_list ();
   foreach (where (bad))
     {
	i = ();
	if (i != i0)
	  {
	     variable ii = [i0:i-1];
	     variable lines = xfig_clip_polyline2d (x[ii], y[ii], 0, w, 0, h);
	     lines.translate (p.X);
	     lines.set_depth (depth);
	     lines.set_thickness (thickness);
	     lines.set_pen_color (color);
	     lines.set_line_style (linestyle);
	     p.object_list.insert(lines);
	  }
	i0 = i+1;
     }
}
%}}}

private define pop_plot_err_parms (nargs) %{{{
{
   variable p, x, y, dy;
   (p, x, y, dy) = ();

   variable 
     i, dy_neg = dy, dy_pos = dy,
     is_asymmetric = (typeof (dy) == List_Type);

   if (is_asymmetric)
     {
        if(qualifier("minmax"))
	  {
	     dy_neg = y - dy[0];  % dy[0]  is actually  y - dy_neg
	     dy_pos = dy[1] - y;  % dy[1]  is actually  dy_pos - y
	  }
        else
	  {
	     dy_neg = dy[0];
	     dy_pos = dy[1];
	  }
	i = wherenot (isnan(x) or isnan(y) or isnan(dy_neg) or isnan(dy_pos));
     }
   else
     i = wherenot (isnan(x) or isnan(y) or isnan(dy_neg));

   if (length (i) != length (x))
     {
	x = x[i];
	y = y[i];
	if (typeof(dy_neg) == Array_Type)
	  dy_neg = dy_neg[i];

	if (is_asymmetric)
	  {
	     if (typeof(dy_pos) == Array_Type)
	       dy_pos = dy_pos[i];
	  }	     
     }
   return p.plot_data, x, y, dy_neg, dy_pos;
}
%}}}

private define insert_errbar_list (p, lines) %{{{
{
   variable depth = qualifier ("depth", p.line_depth);
   variable width = qualifier ("width", p.thickness);
   variable color = qualifier ("color", p.line_color);
   variable style = qualifier ("eb_line", p.line_style);
   color = qualifier ("eb_color", color);
   width = qualifier ("eb_width", width);

   lines.translate(p.X);
   lines.set_depth(depth);
   lines.set_thickness (width);
   lines.set_pen_color (color);
   lines.set_line_style (style);
   p.object_list.insert(lines);
}
%}}}

private define plot_erry () %{{{
{
   variable p, x, y, dy_neg, dy_pos;
   (p, x, y, dy_neg, dy_pos) = pop_plot_err_parms (_NARGS; minmax=qualifier_exists("minmax") || qualifier_exists("yminmax"));
   variable ax, ay;
   (ax, ay) = get_world_axes (p ;; __qualifiers);
   variable term_factor = qualifier ("yeb_factor", qualifier ("eb_factor", 1));
   variable w = p.plot_width, h = p.plot_height;

   x = scale_coords_for_axis (ax, w, x);
   variable y0 = scale_coords_for_axis (ay, h, y-dy_neg);
   variable y1 = scale_coords_for_axis (ay, h, y+dy_pos);

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
	     if (term_factor>0)
	       lines.insert (vector (dx, [y1_i, y1_i], dz));
	  }
	else y1_i = h;

	if (y0_i > 0)
	  {
	     if (term_factor>0)
	       lines.insert (vector (dx, [y0_i, y0_i], dz));
	  }
	else y0_i = 0;

	lines.insert (vector ([x_i, x_i], [y0_i,y1_i], dz));
     }
   insert_errbar_list (p, lines ;; __qualifiers);
}
%}}}

private define plot_errx () %{{{
{
   variable p, x, y, dx_neg, dx_pos;
   (p, x, y, dx_neg, dx_pos) = pop_plot_err_parms (_NARGS; minmax=qualifier_exists("minmax") || qualifier_exists("xminmax"));
   variable ax, ay;
   (ax, ay) = get_world_axes (p ;; __qualifiers);
   variable term_factor = qualifier ("xeb_factor", qualifier ("eb_factor", 1));

   variable w = p.plot_width, h = p.plot_height;

   y = scale_coords_for_axis (ay, h, y);
   variable x0 = scale_coords_for_axis (ax, w, x-dx_neg);
   variable x1 = scale_coords_for_axis (ax, w, x+dx_pos);

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
	     if (term_factor>0)
	       lines.insert (vector ([x1_i, x1_i], dy, dz));
	  }
	else x1_i = w;

	if (x0_i > 0)
	  {
	     if (term_factor>0)
	       lines.insert (vector ([x0_i, x0_i], dy, dz));
	  }
	else x0_i = 0;

	lines.insert (vector ([x0_i, x1_i], [y_i,y_i], dz));
     }
   insert_errbar_list (p, lines ;; __qualifiers);
}
%}}}

%{{{ Routines that define and create the plot symbols

private variable Make_Symbol_Funs = {};

define xfig_plot_add_symbol (name, fun) %{{{
%!%+
%\function{xfig_plot_add_symbol}
%\synopsis{Add a plot symbol}
%\usage{xfig_plot_add_symbol (String_Type name, Ref_Type funct)}
%\description
%  This function may be used to add a new plot symbol of the specified name.
%  The \exmp{funct} parameter specifies a function to be called to create the
%  symbol.  It will be called with a single parameter: a value representing the
%  scale size of the symbol in fig units.  The function must return two arrays
%  representing the X and Y coordinates of the polygons that represent
%  the symbol.  The center of the object is taken to be (0,0).  If more than one
%  polygon is required to represent the object, an array of arrays may be
%  returned.
%!%-
{
   list_append (Make_Symbol_Funs, struct{name=name, fun=fun});
}
%}}}

define xfig_plot_get_symbol_names () %{{{
%!%+
%\function{xfig_plot_get_symbol_names}
%\usage{String_Type[] xfig_plot_get_symbol_names ()}
%\seealso{xfig_plot.plot}
%!%-
{
   variable num = length (Make_Symbol_Funs);
   variable names = String_Type[num];
   _for (0, num-1, 1)
     {
	variable i = ();
	names[i] = Make_Symbol_Funs[i].name;
     }
   return names;
}
%}}}

private define find_symbol (symp) %{{{
{
   variable sym = @symp;
   variable s;

   if (typeof (sym) != String_Type)
     {
        s = Make_Symbol_Funs[sym mod length(Make_Symbol_Funs)];
	@symp = s.name;
	return s.fun;
     }

   foreach s (Make_Symbol_Funs)
     {
	if (s.name == sym)
	  return s.fun;
     }
   return NULL;
}
%}}}

private define make_circle (radius) %{{{
{
   variable point_size = xfig_scale_to_inches (radius) * 80.0;
   variable nsides;
   if (point_size == 0)
     nsides = 1;
   else if (point_size < 16)
     nsides = 4 + (point_size-1)*2;
   else
     nsides = 32;
   return make_nsided_polygon (nsides, 0, 0, radius);
}
%}}}

private define make_point (radius) %{{{
{
   return make_circle (radius/6.0);
}
xfig_plot_add_symbol ("point", &make_point);
%}}}

private define make_triangle_up (radius) %{{{
{
   variable t = [-30, 90, 210, -30] * (PI/180.0);
   return radius * cos (t), radius * sin(t);
}
xfig_plot_add_symbol ("triangle", &make_triangle_up);
%}}}

private define make_square (radius) %{{{
{
   variable t = [-45, 45, 135, 225, -45] * (PI/180.0);
   return radius * cos (t), radius * sin(t);
}
xfig_plot_add_symbol ("square", &make_square);
%}}}

private define make_diamond (radius) %{{{
{
   variable t = [0, 90, 180, 270, 0] * (PI/180.0);
   return 0.5*radius * cos (t), radius * sin(t);
}
xfig_plot_add_symbol ("diamond", &make_diamond);
%}}}

private define make_plus (radius) %{{{
{
   variable x = Array_Type[2];
   variable y = Array_Type[2];
   x[0] = [-radius, radius];  y[0] = [0,0];
   x[1] = [0, 0]; y[1] = [-radius, radius];
   return x,y;
}
xfig_plot_add_symbol ("+", &make_plus);
%}}}

private define make_cross (radius) %{{{
{
   variable x = Array_Type[2];
   variable y = Array_Type[2];
   radius *= sqrt(0.5);
   x[0] = [-radius, radius];  y[0] = [-radius, radius];
   x[1] = [-radius, radius]; y[1] = [radius, -radius];
   return x,y;
}
xfig_plot_add_symbol ("x", &make_cross);
%}}}

private define make_asterisk (radius) %{{{
{
   variable x = Array_Type[3];
   variable y = Array_Type[3];
   variable r1 = radius * cos (PI/3);
   variable r2 = radius * cos (PI/6);
   x[0] = [-radius, radius];  y[0] = [0,0];
   x[1] = [-r1, r1]; y[1] = [-r2, r2];
   x[2] = [-r1, r1]; y[2] = [r2, -r2];
   return x,y;
}
xfig_plot_add_symbol ("*", &make_asterisk);
%}}}

xfig_plot_add_symbol ("circle", &make_circle);

private define make_triangle_down (radius) %{{{
{
   variable t = [30, 150, 270, 30] * (PI/180.0);
   return radius * cos (t), radius * sin(t);
}
xfig_plot_add_symbol ("triangle1", &make_triangle_down);
%}}}

private define make_triangle_left (radius) %{{{
{
   variable t = [60, 180, 300, 60] * (PI/180.0);
   return radius * cos (t), radius * sin(t);
}
xfig_plot_add_symbol ("triangle2", &make_triangle_left);
%}}}

private define make_triangle_right (radius) %{{{
{
   variable t = [0, 120, 240, 0] * (PI/180.0);
   return radius * cos (t), radius * sin(t);
}
xfig_plot_add_symbol ("triangle3", &make_triangle_right);
%}}}

private define make_arrow_internal (size, a, b, c) %{{{
{
   variable xs = Array_Type[2];
   variable ys = Array_Type[2];
   xs[0] = [0, 0]; ys[0] = [0,b]*size;
   xs[1] = [0, a, -a, 0]*size;
   ys[1] = [c, b, b, c]*size;
   return xs, ys;
}
%}}}

private define make_darrow (size) %{{{
{
   return make_arrow_internal (size, 0.3, -1.4, -2);
}
xfig_plot_add_symbol ("darr", &make_darrow);
%}}}

private define make_uarrow (size) %{{{
{
   return make_arrow_internal (size, 0.3, 1.4, 2);
}
xfig_plot_add_symbol ("uarr", &make_uarrow);
%}}}

private define make_larrow (size) %{{{
{
   return exch (make_arrow_internal (size, 0.3, -1.4, -2));
}
xfig_plot_add_symbol ("larr", &make_larrow);
%}}}

private define make_rarrow (size) %{{{
{
   return exch (make_arrow_internal (size, 0.3, 1.4, 2));
}
xfig_plot_add_symbol ("rarr", &make_rarrow);
%}}}

private define make_star (size) %{{{
{
   variable thetas = PI/10.0*(1+2*[0:10]);
   variable y0 = sin(thetas[0]);
   variable small_r = hypot (y0, y0*tan(thetas[2]-thetas[1]));
   variable xs = cos(thetas), ys = sin(thetas);
   xs[[1::2]] *= small_r; ys[[1::2]] *= small_r;
   return size*xs, size*ys;
}
xfig_plot_add_symbol ("star", &make_star);
%}}}
%}}}

private define plot_symbols (p, x, y) %{{{
{
   p = p.plot_data;
   variable ax, ay;
   (ax, ay) = get_world_axes (p ;; __qualifiers);

   variable bad = Int_Type [length(x)+1];
   bad[-1] = 1;

   variable w = p.plot_width, h = p.plot_height;

   x = scale_coords_for_axis (ax, w, x);
   y = scale_coords_for_axis (ay, h, y);

   variable point_size = qualifier ("size", p.point_size);
   variable symbol = qualifier ("sym", "point");

   variable fun = find_symbol (&symbol);
   if (fun == NULL)
     {
	() = fprintf (stderr, "***Warning: symbol %s does not exist-- using point\n", symbol);
	symbol = "point";
	fun = &make_point;
     }
   point_size *= 10;

   if (point_size == 0)
     point_size++;

   variable radius = xfig_scale_from_inches (0.5*point_size/80.0);

   variable color = qualifier ("color", p.point_color);
   color = qualifier ("symcolor", color);
   variable fill_color = qualifier ("fillcolor", color);
   variable depth = qualifier ("depth", p.point_depth);
   depth = qualifier ("symdepth", depth);
   variable area_fill = qualifier ("fill", -1);
   variable size = qualifier ("width", p.thickness);
   size = qualifier ("symwidth",size);
   variable linestyle = qualifier ("symlinestyle", p.line_style);

   variable list = xfig_new_polyline_list ();
   variable x0 = p.X.x;
   variable y0 = p.X.y;
   variable z0 = p.X.z;
   variable sym_xs, sym_ys;
   (sym_xs, sym_ys) = (@fun)(radius);
   variable is_array = (_typeof(sym_xs) == Array_Type);

   foreach (where (bad == 0))
     {
	variable i = ();
	variable lines;
	if (is_array)
	  {
	     _for (0, length (sym_xs)-1, 1)
	       {
		  variable j = ();
		  variable xx_j = sym_xs[j];
		  variable yy_j = sym_ys[j];
		  xx_j += x[i];
		  yy_j += y[i];
		  (xx_j, yy_j) = _xfig_clip_polygon2d (__tmp(xx_j), __tmp(yy_j), 0, w, 0, h);
		  if (length(xx_j) == 0)
		    continue;
		  list.insert (vector(xx_j+x0,yy_j+y0,0*xx_j+z0));
	       }
	     continue;
	  }
	variable xx = sym_xs + x[i];
	variable yy = sym_ys + y[i];
	(xx, yy) = _xfig_clip_polygon2d (__tmp(xx), __tmp(yy), 0, w, 0, h);
	if (length (xx) == 0)
	  continue;

	list.insert (vector(xx+x0,yy+y0,0*xx+z0));
     }
   list.set_pen_color (color);
   list.set_fill_color (fill_color);
   list.set_line_style (linestyle);
   list.set_area_fill (area_fill);
   list.set_thickness (size);
   list.set_depth(depth);
   p.object_list.insert(list);
}

%}}}

private define check_axis (p, axis, init_fun, ticlabels, has_log_qualifier) %{{{
{
   if ((axis.inited == 0) || (axis.needs_setup))
     {
	if (has_log_qualifier)
	  (@init_fun)(p; log, ticlabels=axis.draw_tic_labels);
	else
	  (@init_fun)(p; ticlabels=axis.draw_tic_labels);
	return;
     }

   if (has_log_qualifier && (axis.islog == 0))
     add_axis (p.plot_data, axis, "log", NULL, NULL);
}
%}}}

private define initialize_plot (p, x, y) %{{{
%!%+
%\function{xfig_plot--initialize_plot}
%\synopsis{Qualifiers to initialize the axes of an xfig_plot object:}
%\qualifiers
%\qualifier{xlog}{use a logarithmic x-axis}
%\qualifier{ylog}{use a logarithmic y-axis}
%\qualifier{loglog}{use logarithmic axes}
%\qualifier{padx}{[=0.05]: fraction of xrange to be padded on both sides}
%\qualifier{pady}{[=0.05]: fraction of xrange to be padded on both sides}
%\description
%  The world coordinate system of an xfig_plot object
%  are initialized through the following functions,
%  unless they are already set before:
%\seealso{xfig_plot.plot, xfig_plot.hplot, xfig_plot.plot_png, xfig_plot.plot_pict, xfig_plot.shade_region}
%!%-
{
   variable d = p.plot_data;
   d.num_plots++;

   if (d.num_plots > 1)
     return;

   variable x1axis = d.x1axis;
   variable x2axis = d.x2axis;
   variable y1axis = d.y1axis;
   variable y2axis = d.y2axis;

   variable logx, logy;
   (logx, logy) = get_log_qualifiers (;;__qualifiers);
   logx = logx || x1axis.islog;
   logy = logy || y1axis.islog;

   variable xmin = NULL, xmax = NULL;
   if ((x != NULL) && (y != NULL))
     {
	if (not d.world1_inited
	    || (logx && ((x1axis.xmin <= 0) || (x1axis.xmax <= 0)))
	    || (logy && ((y1axis.xmin <= 0) || (y1axis.xmax <= 0))))
	  do_world_method (p, x, y, 1, 3;; __qualifiers);

	if (not d.world2_inited
	    || (logx && ((x2axis.xmin <= 0) || (x2axis.xmax <= 0)))
	    || (logy && ((y2axis.xmin <= 0) || (y2axis.xmax <= 0))))
	  do_world_method (p, x, y, 2, 3;; __qualifiers);
     }

   check_axis (p, d.x1axis, &x1axis_method, 1, logx);
   check_axis (p, d.x2axis, &x2axis_method, 0, logx);
   check_axis (p, d.y1axis, &y1axis_method, 1, logy);
   check_axis (p, d.y2axis, &y2axis_method, 0, logy);
}
%}}}

private define plot_method () %{{{
%!%+
%\function{xfig_plot.plot}
%\usage{xfig_plot.plot([x,] y);
%\altusage{xfig_plot.plot(x, y, [dx,] dy);}
%}
%\qualifiers
% % qualifiers to initialize the first plot only,
%   see \sfun{xfig_plot--initialize_plot}
%
% % qualifiers to specifiy the world coordinate system,
%   see \sfun{xfig_plot--wcs}
%
% %  general qualifiers:
%\qualifier{color=strval}{color of lines symbols and error bars}
%\qualifier{width=intval}{thickness of lines and error bars}
%\qualifier{depth=intval}{Xfig depth}
%
% % qualifiers for lines and error bars:
%\qualifier{line=intval}{line style for lines and error bars}
%\qualifier{eb_line=intval}{line style for error bars [precendence over line]}
%\qualifier{eb_color=intval}{color of error bars [precedence over color]}
%\qualifier{eb_width=intval}{thickness of error bars [precedence over width]}
%
% % qualifiers for symbols:
%\qualifier{sym=strval}{symbol, see xfig_plot_get_symbol_names}
%\qualifier{symcolor=strval}{color of symbols [precedence over color]}
%\qualifier{size=val}{symbol point size}
%\qualifier{fill=intval (from -1 to 20)}{area fill style}
%\qualifier{fillcolor=strval}{color for filled symbols}
%\qualifier{symlinestyle=intval}{line style to draw symbols}
%\qualifier{symwidth=intval}{thickness of symbol lines [precedence over width]}
%\qualifier{symdepth=intval}{Xfig depth of symbols [precedence over depth]}
%\description
%  If no \exmp{x} values are given, \exmp{x = [1:length(y)]} is assumed.
%  If a symbol is specified, no lines are drawn
%  unless the line qualifier is also specified.
%\seealso{xfig_plot--initialize-plot, xfig_plot--wcs}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.plot")) return;
   variable x, y, dx = NULL, dy = NULL, p;

   switch (_NARGS)
     {
      case 2:
	y = ();
	x = [1:length(y)];
     }
     {
      case 3:
	(x,y) = ();
     }
     {
      case 4:
	(x,y,dy) = ();
     }
     {
      case 5:
	(x,y,dx,dy) = ();
     }
     {
	_pop_n (_NARGS);
	usage (".plot (x [, y [, dy | dx, dy]] ; qualifiers\n" +
	       "Common qualifiers:\n" +
	       " color=val, line=val, width=val, sym=val, symcolor=val\n"
	      );
     }
   p = ();
   initialize_plot (p, x, y ;;__qualifiers);

   % If a symbol is specified, then do not draw lines unless line is
   % also specified.
   variable line = qualifier ("line");
   variable sym = qualifier ("sym");

   if ((line != NULL) || (sym == NULL))
     {
	plot_lines (p, x, y ;; __qualifiers);
     }
   if (sym != NULL)
     {
	plot_symbols (p, x, y ;; __qualifiers);
     }
   if (dx != NULL)
     {
	plot_errx (p, x, y, dx;; __qualifiers);
     }
   if (dy != NULL)
     {
	plot_erry (p, x, y, dy;; __qualifiers);
     }
}

%}}}

private define plot_histogram (w, xpts, ypts) %{{{
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
   initialize_plot (w, x, y ;;__qualifiers);
   plot_lines (w, x, y ;; __qualifiers);
}
%}}}

private define plot_shaded_histogram (p, x, y) %{{{
{
   initialize_plot (p, x, y ;;__qualifiers);

   p = p.plot_data;
   variable ax, ay;
   (ax, ay) = get_world_axes (p ;; __qualifiers);
   variable w = p.plot_width, h = p.plot_height;
   x = scale_coords_for_axis (ax, w, x);
   y = scale_coords_for_axis (ay, h, y);

   variable depth = qualifier ("depth", p.line_depth);
   variable thickness = qualifier ("width", p.thickness);
   variable color = qualifier ("color", p.line_color);
   variable linestyle = qualifier ("line", p.line_style);
   variable area_fill = qualifier ("fill", 20);
   variable fillcolor = qualifier ("fillcolor", color);

   variable y0 = scale_coords_for_axis (ay, h, 0.0);
   if (y0 < 0.0) y0 = 0.0;

   x = @x;
   variable i0 = wherelast (x <= 0);
   if (i0 == NULL) i0 = 0;
   variable i1 = wherefirst (x >= w);
   if (i1 == NULL) i1 = length(x);
   variable i = [i0:i1-1];
   %variable i = where ((x>= 0) and (x <= w));
   x = x[i]; y = y[i];
   x[where(x<0)] = 0;
   x[where(x>w)] = w;
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

	list.insert (vector([x0, x0, x1, x1], [y0,y1,y1,y0], [0.0,0.0,0.0,0.0]));
     }
   list.translate (p.X);
   list.set_depth (p.line_depth+1);
   list.set_pen_color (color);
   list.set_line_style (linestyle);
   list.set_fill_color (fillcolor);
   list.set_area_fill (area_fill);
   p.object_list.insert (list);
}
%}}}

private define hplot_method () %{{{
%!%+
%\function{xfig_plot.hplot}
%\usage{xfig_plot.hplot([x,] y);
%\altusage{xfig_plot.hplot(x, y[, dy]);}
%}
%\qualifiers
% % qualifiers to initialize the first plot only,
%   see \sfun{xfig_plot--initialize_plot}
%
% % qualifiers to specifiy the world coordinate system,
%   see \sfun{xfig_plot--wcs}
%
%\qualifier{fill}{plot shaded histogram}
%\qualifier{depth}{}
%\qualifier{thickness}{}
%\qualifier{color}{}
%\qualifier{line}{linestyle}
%\qualifier{width}{}
%\qualifier{eb_factor}{}{1}
%\description
%  If no \exmp{x} values are given, \exmp{x = [1:length(y)]} is assumed.
%\seealso{xfig_plot--initialize-plot, xfig_plot--wcs}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.hplot")) return;

   variable x, y, dy = NULL, p;

   switch (_NARGS)
     {
      case 2:
	y = ();
	x = [1:length(y)];
     }
     {
      case 3:
	(x,y) = ();
     }
     {
      case 4:
	(x,y,dy) = ();
     }
     {
	_pop_n (_NARGS);
	usage (".hplot (x [, y [, dy ]] ; qualifiers\n" +
	       "Common qualifiers:\n" +
	       " color=val, line=val, width=val\n"
	      );
     }
   p = ();

   if (NULL != qualifier ("fill"))
     plot_shaded_histogram (p, x, y;; __qualifiers);
   else
     plot_histogram (p, x, y;; __qualifiers);

   if (dy != NULL)
     {
	variable xhi = shift(x,1);
	xhi[-1] = 2*x[-1] - x[-2];
	x = 0.5*(x+xhi);  % FIX ME: for non-linear wcs, a more reasonable choice might have to be found
	plot_erry (p, x, y, dy ;; __qualifiers);
     }
}
%}}}

define xfig_plot_set_line_color (p, color)
{
   p.plot_data.line_color = color;
}

define xfig_plot_set_line_style (p, style)
{
   p.plot_data.line_style = style;
}

define xfig_plot_set_line_thickness (p, thickness)
{
   p.plot_data.thickness = thickness;
}

define xfig_plot_set_line_depth (p, depth)
{
   p.plot_data.line_depth = depth;
}
define xfig_plot_set_axis_depth (p, depth)
{
   p.plot_data.axis_depth = depth;
}
define xfig_plot_set_point_depth (p, depth)
{
   p.plot_data.point_depth = depth;
}
define xfig_plot_inc_line_depth (p, depth)
{
   p.plot_data.line_depth += depth;
}
define xfig_plot_inc_axis_depth (p, depth)
{
   p.plot_data.axis_depth += depth;
}
define xfig_plot_inc_point_depth (p, depth)
{
   p.plot_data.point_depth += depth;
}
define xfig_plot_get_line_depth (p)
{
   return p.plot_data.line_depth;
}
define xfig_plot_get_axis_depth (p)
{
   return p.plot_data.axis_depth;
}
define xfig_plot_get_point_depth (p)
{
   return p.plot_data.point_depth;
}

define xfig_plot_inc_image_depth (p, depth)
{
   p.plot_data.image_depth += depth;
}
define xfig_plot_get_image_depth (p)
{
   return p.plot_data.image_depth;
}
define xfig_plot_set_image_depth (p, depth)
{
   p.plot_data.image_depth = depth;
}

define xfig_plot_set_point_size (p, point_size)
{
   if (point_size < 0)
     point_size = 0;
   p.plot_data.point_size = point_size;
}
define xfig_plot_set_point_color (p, color)
{
   p.plot_data.point_color = color;
}

private define add_object_method () %{{{
%!%+
%\function{xfig_plot.add_object}
%\synopsis{Add an object to a plot at a world coordinate position}
%\usage{xfig_plot.add_object (obj[, x, y[, dx, dy]]);}
%\description
%  This function may be used to add an object to a plot window at a specified
%  world coordinate.  The \exmp{dx} and \exmp{dy} arguments control the
%  justification of the object.  The values of these parameters are offsets
%  relative to the size of the object, and as such ordinarily have values
%  in the interval \exmp{[-0.5,0.5]}.  For example, \exmp{0,0} will center
%  the object on \exmp{(x,y)}, and \exmp{(-0.5,-0.5)} will move the lower left
%  corner of the object to the specified coordinate.
%\seealso{xfig_plot--wcs}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.add_object")) return;

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

   p = p.plot_data;

   if ((x != NULL) and (y != NULL))
     {
	variable ax, ay;
	(ax, ay) = get_world_axes (p ;; __qualifiers);
	x = scale_coords_for_axis (ax, p.plot_width, x);
	y = scale_coords_for_axis (ay, p.plot_height, y);

	xfig_justify_object (obj, p.X + vector (x,y,0), vector(dx, dy, 0));
     }

   p.object_list.insert(obj);
}
%}}}

define xfig_plot_text () %{{{
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
{
   variable w, text, x, y, dx = 0, dy = 0;
   if (_NARGS == 6)
     (dx, dy) = ();
   else if (_NARGS != 4)
     usage ("%s (win, text, x, y [, dx, dy]);", _function_name);
   (w, text, x, y) = ();

   text = xfig_new_text (text;; __qualifiers);
   add_object_method (w, text, x, y, dx, dy;; __qualifiers);
}
%}}}

private define xylabel_method () %{{{
%!%+
%\function{xfig_plot.xylabel}
%\usage{xfig_plot.xylabel (String_Type text, Double_Type x, y[, dx, dy]);}
%\seealso{xfig_plot_text, xfig_plot--wcs}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.xylabel")) return;

   variable w, text, x, y, dx = 0, dy = 0;
   if (_NARGS == 6)
     (dx, dy) = ();
   else if (_NARGS != 4)
     usage (".xylabel(x, y, text [, dx, dy]);");
   (w, x, y, text) = ();  % Note the different order of the arguments.

   xfig_plot_text(w, text, x, y, dx, dy;; __qualifiers);
}
%}}}

private define xlabel_method () %{{{
%!%+
%\function{xfig_plot.xlabel}
%\synopsis{Add an x-axis label to a plot}
%\usage{xfig_plot.xlabel (String_Type xlabel);}
%\description
%  The x-label is created from the string with the
%  \sfun{xfig_new_text} function using all applied qualifiers.
%\seealso{xfig_new_text}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.xlabel")) return;
   if (_NARGS != 2)  usage (".xlabel (label [; qualifiers])");

   variable p, label;
   (p, label) = ();
   p = p.plot_data;
   add_axis_label (p, p.x1axis, label ;; __qualifiers);
}
%}}}

private define ylabel_method () %{{{
%!%+
%\function{xfig_plot.ylabel}
%\synopsis{Add a y-axis label to a plot}
%\usage{xfig_plot.ylabel (String_Type ylabel);}
%\description
%  The ylabel is created from the string with the
%  \sfun{xfig_new_text} function using all applied qualifiers.
%\seealso{xfig_new_text}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.ylabel")) return;
   if (_NARGS != 2)  usage (".ylabel (label [; qualifiers])");
   variable p, label;
   (p, label) = ();
   p = p.plot_data;
   add_axis_label (p, p.y1axis, label ;; __qualifiers);
}
%}}}

private define x2label_method () %{{{
%!%+
%\function{xfig_plot.x2label}
%\synopsis{Add a label for the second x-axis to a plot}
%\usage{xfig_plot.x2label (String_Type x2label);}
%\description
%  The x2label is created from the string with the
%  \sfun{xfig_new_text} function using all applied qualifiers.
%\seealso{xfig_new_text}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.x2label")) return;
   if (_NARGS != 2)  usage (".x2label (label [; qualifiers])");
   variable w, p, label;
   (w, label) = ();
   p = w.plot_data;
   add_axis_label (p, p.x2axis, label ;; __qualifiers);

   % re-adjust the title position
   if (p.title_object != NULL)
     w.title (p.title_object);
}
%}}}

private define y2label_method () %{{{
%!%+
%\function{xfig_plot.y2label}
%\synopsis{Add a label for the second y-axis to a plot}
%\usage{xfig_plot.y2label(String_Type y2label);}
%\description
%  The y2label is created from the string with the
%  \sfun{xfig_new_text} function using all applied qualifiers.
%\seealso{xfig_new_text}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.xylabel")) return;
   if (_NARGS != 2)  usage (".y2label (label [; qualifiers])");
   variable p, label;
   (p, label) = ();
   p = p.plot_data;
   add_axis_label (p, p.y2axis, label ;; __qualifiers);
}
%}}}

private define title_method (w, title) %{{{
%!%+
%\function{xfig_plot.title}
%\synopsis{Add a title to a plot}
%\usage{xfig_plot.title (String_Type title);
%\altusage{xfig_plot.title(XFig_Object title);}
%}
%\description
%  The title is created from the string with the
%  \sfun{xfig_new_text} function using all applied qualifiers.
%  If \exmp{title} is no string, it is assumed to be
%  an already properly formatted xfig object.
%  The title is centered above the plot area.
%  Any previously existing title object is removed.
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.title")) return;

   variable x0, x1, y, z;
   variable p = w.plot_data;

   % remove the existing title
   p.title_object = NULL;

   (,,,y,,z) = w.get_bbox ();

   x0 = p.X.x;
   x1 = x0 + p.plot_width;

   if (typeof (title) == String_Type)
     title = xfig_new_text (title ;; __qualifiers);

   xfig_justify_object (title, vector(0.5*(x0+x1), y, z), vector(0,-1.0,0));
   p.title_object = title;
}
%}}}

private define add_pict_to_plot (w, png) %{{{
{
   variable dx, dy;
   (dx, dy) = png.get_pict_bbox ();
   variable p = w.plot_data;
   variable width = p.plot_width;
   variable height = p.plot_height;
   png.scale_pict (width/dx, height/dy);

   png.center_pict (p.X + 0.5*vector (width,height,0), width, height);
   w.add_object (png);
   png.set_depth (p.image_depth);
}
%}}}

define plot_png_method () %{{{
%!%+
%\function{xfig_plot.plot_png}
%\synopsis{Add a png file to a plot, scaling it to the window}
%\usage{xfig_plot.plot_png (String_Type pngfile);}
%\qualifiers
% % qualifiers to initialize the first plot only,
%   see \sfun{xfig_plot--initialize_plot}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.plot_png")) return;

   variable w, png;
   if (_NARGS != 2)
     usage (".plot_png (img)");

   (w, png) = ();
   png = xfig_new_png (png);
   initialize_plot (w, NULL, NULL ;;__qualifiers);
   add_pict_to_plot (w, png);
}
%}}}

private define plot_pict_method () %{{{
%!%+
%\function{xfig_plot.plot_pict}
%\usage{xfig_plot.plot_pict (String_Type imgfile);}
%\qualifiers
% % qualifiers to initialize the first plot only,
%   see \sfun{xfig_plot--initialize_plot}
%!%-
{
   if (_xfig_check_help (_NARGS, "xfig_plot.plot_pict")) return;

   variable w, img;
   if (_NARGS != 2)
     usage (".plot_pict (img)");
   (w, img) = ();

   variable dx=4., dy=3.;  % numbers do not matter here, will be scaled anyway
   variable pict = xfig_new_pict(img, dx, dy);

   initialize_plot (w, NULL, NULL;; __qualifiers);

   variable p = w.plot_data;
   variable width = p.plot_width;
   variable height = p.plot_height;
   pict.scale_pict (width/dx, height/dy);
   pict.center_pict (p.X + 0.5*vector (width,height,0), width, height);
   w.add_object (pict);
   pict.set_depth (p.image_depth);
}
%}}}

private define shade_region_method () %{{{
%!%+
%\function{xfig_plot.shade_region}
%\usage{xfig_plot.shade_region(x[], y[]);
%\altusage{xfig_plot.shade_region (xmin, xmax, ymin, ymax);}
%}
%\qualifiers
% % qualifiers to initialize the first plot only
% % qualifiers to specifiy the world coordinate system
%\seealso{xfig_plot--initialize_plot, xfig_plot--wcs}
%!%-
{
   variable p, w, xs, ys, xmin, xmax, ymin, ymax;

   switch (_NARGS)
     {
      case 3:
	(w, xs, ys) = ();
     }
     {
      case 5:
	(w, xmin, xmax, ymin, ymax) = ();
	xs = [xmin, xmax, xmax, xmin, xmin];
	ys = [ymin, ymin, ymax, ymax, ymin];
     }
     {
	usage ("Usage forms:\n"
	       + " .shade_region (xs, ys; qualifiers);\n"
	       + " .shade_region (xmin, ymin, xmax, ymax; qualifiers);\n"
	       + "Qualifiers\n"
	       + " world[012][012], fill=value, color=value, fillcolor=value");
     }

   if (length (xs) < 3)
     return;

   initialize_plot (w, xs, ys ;;__qualifiers);

   p = w.plot_data;
   variable ax, ay;
   (ax, ay) = get_world_axes (p ;; __qualifiers);
   variable width = p.plot_width, height = p.plot_height;
   xs = scale_coords_for_axis (ax, width, xs);
   ys = scale_coords_for_axis (ay, height, ys);

   xs[where(xs>width)]=width; xs[where(xs<0)] = 0;
   ys[where(ys>height)]=height; ys[where(ys<0)] = 0;

   xs[where(isnan(xs))] = 0;
   ys[where(isnan(ys))] = 0;

   variable obj = xfig_new_polyline (vector (xs, ys, 0*xs));
   obj.translate (p.X);

   obj.set_depth (qualifier ("depth", p.image_depth));
   obj.set_thickness (qualifier ("width", p.thickness));
   variable color = qualifier ("color", p.line_color);
   obj.set_pen_color (color);
   obj.set_line_style (qualifier ("line", p.line_style));
   obj.set_area_fill(qualifier ("fill", 20));
   obj.set_fill_color (qualifier ("fillcolor", color));

   w.add_object (obj);
}
%}}}

% Usage: [xmin,xmax,ymin,ymax] = w.get_world();
private define get_world_method (w)
{
   variable p = w.plot_data;

   variable ax, ay;
   (ax, ay) = get_world_axes (p ;; __qualifiers);
   
   return [get_world_for_axis(ax), get_world_for_axis(ay)];   
}

private variable XFig_Plot_Type = struct %{{{
{
   plot_data,

   % Methods
   title = &title_method,
   add_object = &add_object_method,
   world = &world_method,
   world1 = &world1_method,
   world2 = &world2_method,
   plot = &plot_method,
   hplot = &hplot_method,
   xlabel = &xlabel_method,
   ylabel = &ylabel_method,
   x2label = &x2label_method,
   y2label = &y2label_method,
   x1axis = &x1axis_method,
   y1axis = &y1axis_method,
   x2axis = &x2axis_method,
   y2axis = &y2axis_method,
   xaxis = &xaxis_method,
   yaxis = &yaxis_method,
   axis = &axis_method,
   axes = &axis_method,
   xylabel = &xylabel_method,
   plot_png = &plot_png_method,
   plot_pict = &plot_pict_method,
   shade_region= &shade_region_method,
   get_world = &get_world_method,
   xfig_coords=&xfig_coords_method,
};
%}}}

private variable Default_Width = 14.0;
private variable Default_Height = 10.0;
define xfig_plot_set_default_size (w, h)
{
   Default_Width = w;
   Default_Height = h;
}
define xfig_plot_get_default_size ()
{
   return Default_Width, Default_Height;
}

define xfig_plot_new () %{{{
%!%+
%\function{xfig_plot_new}
%\synopsis{Create a new plot object}
%\usage{w = xfig_plot_new ( [Int_Type width, Int_Type height] );}
%\description
%  This function creates a new plot object of the specified width and height.
%  If the width and height parameters are not given, defaults will be used.
%  The width and height values specify the size of the plotting area and do not
%  include the space for tic marks and labels.
%\example
%#v+
%   w = xfig_plot_new ();
%#v-
%\seealso{xfig_plot_define_world, xfig_render_object}
%!%-
{
   variable w, h;
   if (_NARGS == 0)
     (Default_Width, Default_Height);
   (w, h) = ();

   variable p = @XFig_Plot_Data_Type;
   p.plot_width = w;
   p.plot_height = h;
   variable maxticsx = int(w*0.5 + 1.5);
   variable maxticsy = int(h+1.5);
   p.x1axis = allocate_axis_type (w, maxticsx, 1, (0,0), (1,0), (0,1), X1_Axis_Geom);
   p.y1axis = allocate_axis_type (h, maxticsy, 1, (0,0), (0,1), (1,0), Y1_Axis_Geom);
   p.x2axis = allocate_axis_type (w, maxticsx, 0, (0,h), (1,0), (0,-1), X2_Axis_Geom);
   p.y2axis = allocate_axis_type (h, maxticsy, 0, (w,0), (0,1), (-1,0), Y2_Axis_Geom);

   p.line_color = "black";
   p.line_style = 0;
   p.thickness = 2;
   p.point_color = "black";
   p.point_size = 1;
   p.line_depth = DEFAULT_LINE_DEPTH;
   p.point_depth = DEFAULT_POINT_DEPTH;
   p.axis_depth = DEFAULT_FRAME_DEPTH;
   p.image_depth = DEFAULT_IMAGE_DEPTH;

   p.X = vector(0,0,0);
   p.object_list = xfig_new_compound_list ();

   variable obj = xfig_new_object (@XFig_Plot_Type);
   obj.plot_data = p;

   obj.render_to_fp = &plot_render;
   obj.rotate = &plot_rotate;
   obj.translate = &plot_translate;
   obj.scale = &plot_scale;
   obj.get_bbox = &plot_get_bbox;
   obj.flags |= XFIG_RENDER_AS_COMPOUND;
   return obj;
}
%}}}

define xfig_plot_new_png (png) %{{{
%!%+
%\function{xfig_plot_new_png}
%\synopsis{Create a new plot window for a png file}
%\usage{w = xfig_plot_new_png (file)}
%\description
%  TBD
%\example
%  TBD
%\seealso{xfig_new_object}
%!%-
{
   png = xfig_new_png (png);
   variable dx, dy;
   (dx, dy) = png.get_pict_bbox ();
   variable w = xfig_plot_new (dx, dy);
   add_pict_to_plot (w, png);
   return w;
}
%}}}

private define ones()
{
   !if (_NARGS) return 1;
   variable a = __pop_args (_NARGS);
   return 1 + Int_Type[__push_args (a)];
}

define xfig_meshgrid () %{{{
%!%+
%\function{xfig_meshgrid}
%\synopsis{Produce grid points for an image}
%\usage{(xx,yy) = xfig_meshgrid (xx, yy)}
%\description
%  This function takes two 1-d vectors representing the orthogonal
%  grids for a rectangular region in the (x,y) plane and returns two
%  2-d arrays corresponding to the (x,y) coordinates of each
%  intersecting grid point.
%
%  Suppose that one wants to evaluate a
%  function \exmp{f(x,y)} at each point defined by the two grid
%  vectors.  Simply calling \exmp{f(x,y)} using the grid vectors would
%  lead to either a type-mismatch error or produce a 1-d result.  The
%  correct way to do this is to use the \sfun{xfig_meshgrid} function:
%#v+
%    result = f(xfig_meshgrid(x,y));
%#v-
%!%-
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
%}}}

define xfig_multiplot () %{{{
%!%+
%\function{xfig_multiplot}
%\synopsis{Create a multiplot from individual panels that share the same x-axes}
%\usage{compound = xfig_multiplot(xfig_plot p1, p2, ...);}
%\description
%  The function switches the appropriate labels and ticmark labels off and
%  returns a compound object consisting of the accordingly translated plots.
%\qualifiers
%\qualifier{title=strval}{title for top panel}
%\qualifier{xlabel=strval}{xlabel for bottom panel}
%\qualifier{x2label=strval}{x2label for top panel}
%!%-
{
   variable i, dy = 0., args = __pop_list(_NARGS);
   _for i (1, _NARGS-1, 1)
     {
	dy -= args[i].plot_data.plot_height;
	args[i].translate( vector(0, dy, 0) );
	args[i].x2axis(; ticlabels=0);
	args[i].plot_data.x2axis.axis_label = NULL;
	args[i].plot_data.title_object = NULL;
     }
   _for i (0, _NARGS-2, 1)
     {
	args[i].x1axis(; ticlabels=0);
	args[i].plot_data.x1axis.axis_label = NULL;
     }

   if(qualifier_exists("title"))
     args[0].title(qualifier("title"));
   if(qualifier_exists("x2label"))
     args[0].x2label(qualifier("x2label"));
   if(qualifier_exists("xlabel"))
     args[-1].xlabel(qualifier("xlabel"));
   
   return xfig_new_compound( __push_list(args) );
}
%}}}
