require ("vector");

private variable Eye;
private variable PIX_PER_INCH = 1200.0; %  xfig units per inch
private variable XFig_Origin_X = 10.795;%  [cm]
private variable XFig_Origin_Y = 13.97; %  [cm]
private variable Origin = vector (0, 0, 0);
private variable Focus = vector (0, 0, 0);

% XFig has a strange notion about what a cm is--- not 1200/2.54.
private variable PIX_PER_CM = 450.0; 
private variable DISPLAY_PIX_PER_INCH = 80;
private variable Scale_Factor;
private variable Display_Pixel_Size;

define xfig_get_focus ()
{
   return Focus;
}

define xfig_set_eye (dist, theta, phi)
{
   theta *= PI/180.0;
   phi *= PI/180.0;

   variable x = dist * sin(theta)*cos(phi);
   variable y = dist * sin(theta)*sin(phi);
   variable z = dist * cos(theta);

   Eye = vector_sum (vector(x,y,z), xfig_get_focus ());
   %exit (0);
}

define xfig_set_focus (X)
{
   Focus = X;
}

define xfig_get_eye ()
{
   return Eye;
}

define xfig_convert_inches (x)
{
   return int (PIX_PER_INCH * x + 0.5);
}

define xfig_convert_cm (x)
{
   return int (PIX_PER_CM*x + 0.5);
}

define xfig_convert_units (x)
{
   return int (Scale_Factor * x + 0.5);
}

define xfig_use_inches ()
{
   Scale_Factor = PIX_PER_INCH;
   Display_Pixel_Size = 1.0/DISPLAY_PIX_PER_INCH;
}
define xfig_use_cm ()
{
   Scale_Factor = PIX_PER_CM;
   Display_Pixel_Size = 2.54/DISPLAY_PIX_PER_INCH;
}

% Scale from inches to user system 
define xfig_scale_from_inches (x)
{
   return x*(PIX_PER_INCH/Scale_Factor);
}


% Xfig scales the image pixels (e.g., png) to its pixel system using the factor
%   PIX_PER_INCH/DISPLAY_PIX_PER_INCH
% when inches are used, and
%   (2.54*PIX_PER_CM)/DISPLAY_PIX_PER_INCH
% when cm are used.
% where DISPLAY_PIX_PER_INCH is 80.  Note also that in Xfig, 
% PIX_PER_INCH/PIX_PER_CM is _not_ 2.54.  The scale factor represents
% the number of Xfig pixels per image-pixel.
% The function below supplies the correct scaling for images that have no
% predefined units.
define xfig_get_display_pix_size ()
{
   return Display_Pixel_Size;
}

define xfig_set_origin (x, y)
{
   XFig_Origin_X = x;
   XFig_Origin_Y = y;
}

define xfig_transform_vector (X, xhat, yhat, zhat, X0, scale)
{
   X = vector_change_basis (X, xhat, yhat, zhat);
   return vector_sum (X0, vector_mul (scale, X));
}

private define intersect_focal_plane (X, n)
{
   %variable dX = vector_diff (X, Focus);
   variable X_E = vector_diff (X, Eye);
   %variable t = -dotprod (de, de)/dotprod (de, X_E);
   %return vector_sum (de, vector_mul (t, X_E));
   
   %variable t = -dotprod (de, dX)/dotprod (de, X_E);
   %return vector_sum (X, vector_mul (t, X_E));

   variable t = -dotprod(n, Eye)/dotprod(n, X_E);
   return vector_sum (Eye, vector_mul (t, X_E));
}

define xfig_project_to_xfig_plane (X)
{
   variable origin = Focus;
   variable zhat = vector_diff (Eye, origin);
   normalize_vector (zhat);

   X = intersect_focal_plane (X, zhat);
   
   variable yhat = vector_sum (origin, vector (0, 1, 0));
   yhat = intersect_focal_plane (yhat, zhat);
   origin = intersect_focal_plane (origin, zhat);
   yhat = vector_diff (yhat, origin);
   normalize_vector (yhat);
   variable xhat = crossprod (yhat, zhat);

   variable x = dotprod (X,xhat); 
   variable y = dotprod (X,yhat);
   
   y = -y;
   x += XFig_Origin_X;
   y += XFig_Origin_Y;
   return (x, y);
}

private variable XFig_Header = struct
{
   orientation, justification, units, papersize,
     magnification, multiple_page,
     transparant_color, resolution_coord_system,
};

XFig_Header.orientation = "Portrait";
XFig_Header.justification = "Center";
XFig_Header.units = "Metric";
XFig_Header.papersize = "Letter";
XFig_Header.magnification = 100;       %  percent
XFig_Header.multiple_page = "Single";
XFig_Header.transparant_color = -1;    %  default
XFig_Header.resolution_coord_system = [PIX_PER_INCH, 2];

define xfig_vwrite ()
{
   variable args = __pop_args (_NARGS);
   () = fprintf (__push_args (args));
}

define xfig_write (fp, x)
{
   () = fprintf (fp, "%s", x);
}

define xfig_write_header (fp, h)
{
   if (h == NULL)
     h = @XFig_Header;

   xfig_write (fp, "#FIG 3.2\n");
   xfig_vwrite (fp, "%s\n", h.orientation);
   xfig_vwrite (fp, "%s\n", h.justification);
   xfig_vwrite (fp, "%s\n", h.units);
   xfig_vwrite (fp, "%s\n", h.papersize);
   xfig_vwrite (fp, "%g\n", h.magnification);
   xfig_vwrite (fp, "%s\n", h.multiple_page);
   xfig_vwrite (fp, "%d\n", h.transparant_color);
   xfig_vwrite (fp, "%g %g\n", h.resolution_coord_system[0], h.resolution_coord_system[1]);
}

private variable Fig2dev_Formats = Assoc_Type[String_Type];


%!%+
%\function{xfig_set_output_driver}
%\synopsis{Associate an output driver to a file extension}
%\usage{xfig_set_output_driver (String_Type ext, String_Type cmd)}
%\description
% This may may be used to define the command that runs to created the specified
% output format (dictated by the extension) from the corresponding .fig file.
% The \exmp{ext} parameter specifies the filename extension and \exmp{cmd} is
% the shell command that will be used to generate the file.
% 
% The \exmp{cmd} may contain the following format descriptors that will be 
% replace by the corresponding objects before being passed to the shell:
%#v+
%   %I    Input .fig file
%   %O    Output file
%   %P    paper-size
%   %B    basename of the file
%#v-
%\example
% The default driver for postscript output is given by:
%#v+
%  xfig_set_output_driver ("ps", "fig2dev -L ps -c -z %P %I %O");
%#v-
% The \var{ps2ps} command may result in a smaller file size at a slight cost
% of resolution.  It may be used as follows:
%#v+
%    xfig_set_output_driver ("ps", "fig2dev -L ps -c -z %P %I %B-tmp.ps"
%                             + ";ps2ps %B-tmp.ps %O; rm -f %B-tmp.ps");
%#v-
%\seealso{xfig_set_paper_size}
%!%-

define xfig_set_output_driver (ext, cmd)
{
   Fig2dev_Formats[ext] = cmd;
}
xfig_set_output_driver("eps", "fig2dev -L eps -z %P %I %O");
xfig_set_output_driver("ps", "fig2dev -L ps -c -z %P %I %O");
xfig_set_output_driver("png", "fig2dev -L png %I %O");
xfig_set_output_driver("gif", "fig2dev -L gif %I %O");


private define get_fig2dev_cmd (ext)
{
   ext = ext[[1:]];
   variable fmt = Fig2dev_Formats[ext];
   if (fmt == NULL)
     {
	vmessage ("*** Warning: %s format may not be supported by fig2dev", ext);
	return fmt;
     }
   return fmt;
}

define xfig_create_file (file)
{
   variable dev = struct 
     {
	fp, figfile, devfile, papersize, fig2dev_fmt
     };

   variable cwd = getcwd ();
   file = path_concat (cwd, file);

   variable ext = path_extname (file);
   variable base = path_sans_extname (file);
   variable figfile = strcat (base, ".fig");
   if (ext != ".fig")
     {
	dev.devfile = file;
	dev.fig2dev_fmt = get_fig2dev_cmd (ext);
     }
   dev.figfile = figfile;
   variable fp = fopen (figfile, "w");
   if (fp == NULL)
     verror ("Unable to open %s\n", figfile);
   dev.fp = fp;
   dev.papersize = XFig_Header.papersize;	
   xfig_write_header (fp, NULL);
   return dev;
}

define xfig_close_file (dev)
{
   if (-1 == fclose (dev.fp))
     throw WriteError, sprintf ("xfig_close_file failed: %S", errno_string (errno));

   variable fmt = dev.fig2dev_fmt;
   if (fmt == NULL)
     return;

   (fmt,) = strreplace (fmt, "%P", dev.papersize, strlen(fmt));
   (fmt,) = strreplace (fmt, "%I", dev.figfile, strlen(fmt));
   (fmt,) = strreplace (fmt, "%O", dev.devfile, strlen(fmt));
   (fmt,) = strreplace (fmt, "%B", path_sans_extname(dev.figfile), strlen(fmt));

   () = system (fmt);
}


% Colors
private variable Color_Table = Assoc_Type[Int_Type];
Color_Table["default"]	= -1;
Color_Table["black"]	= 0;
Color_Table["blue"]	= 1;
Color_Table["green"]	= 2;
Color_Table["cyan"]	= 3;
Color_Table["red"]	= 4;
Color_Table["magenta"]	= 5;
Color_Table["yellow"]	= 6;
Color_Table["white"]	= 7;
Color_Table["blue1"]	= 8;
Color_Table["blue2"]	= 9;
Color_Table["blue3"]	= 10;
Color_Table["blue4"]	= 11;
Color_Table["green1"]	= 12;
Color_Table["green2"]	= 13;
Color_Table["green3"]	= 14;
Color_Table["cyan1"]	= 15;
Color_Table["cyan2"]	= 16;
Color_Table["cyan3"]	= 17;
Color_Table["red1"]	= 18;
Color_Table["red2"]	= 19;
Color_Table["red3"]	= 20;
Color_Table["magenta1"]	= 21;
Color_Table["magenta2"]	= 22;
Color_Table["magenta3"]	= 23;
Color_Table["brown1"]	= 24;
Color_Table["brown2"]	= 25;
Color_Table["brown3"]	= 26;
Color_Table["pink1"]	= 27;
Color_Table["pink2"]	= 28;
Color_Table["pink3"]	= 29;
Color_Table["pink4"]	= 30;
Color_Table["gold"]	= 31;

define xfig_lookup_color (color)
{
   color = strlow (color);
   if (assoc_key_exists (Color_Table, color))
     return Color_Table[color];
   
   () = fprintf (stderr, "color %s is unknown\n", color);
   return -1;
}

private variable XFig_Object = struct
{
   object, render_fun, rotate_fun, translate_fun, scale_fun,
     set_attr_fun, get_bbox_fun,
     flags,
     next
};
% Bitmapped values for flags parameter
variable XFIG_RENDER_AS_COMPOUND = 1;

define xfig_primative_set_attr (p, attr, val)
{
   variable names = get_struct_field_names (p);
   if (0 == length (where (names == attr)))
     return;
   set_struct_field (p, attr, val);
}

private define default_render (object, fp)
{
}

private define default_rotate (object, axis, theta)
{
}

private define default_translate (object, X0)
{
}

private define default_scale (object, sx, sy, sz)
{
}

private define default_set_attr (object, attr, val)
{
   xfig_primative_set_attr (object, attr, val);
}

private define default_get_bbox (object)
{
   verror ("*** Warning: %S has no get_bbox_fun method", object);
   return (0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
}

define xfig_new_object (object)
{
   variable obj = @XFig_Object;
   obj.object = object;
   obj.render_fun = &default_render;
   obj.rotate_fun = &default_rotate;
   obj.translate_fun = &default_translate;
   obj.scale_fun = &default_scale;
   obj.set_attr_fun = &default_set_attr;
   obj.get_bbox_fun = &default_get_bbox;
   obj.flags = 0;
   return obj;
}

define xfig_translate_object ()
{
   variable obj, dX;
   switch (_NARGS)
     {
      case 3:
	dX = __pop_args (2);
	dX = vector (__push_args (dX), 0);
	obj = ();
     }
     {
      case 4:
	dX = __pop_args (3);
	dX = vector (__push_args (dX));
	obj = ();
     }
     {
	(obj, dX) = ();
     }

   if (obj == NULL)
     return;
   (@obj.translate_fun)(obj.object, dX);
}

define xfig_rotate_object (obj, axis, theta)
{
   if (obj == NULL)
     return;
   (@obj.rotate_fun)(obj.object, axis, theta);
}

define xfig_scale_object (obj, sx, sy, sz)
{
   if (obj == NULL)
     return;
   (@obj.scale_fun)(obj.object, sx, sy, sz);
}

define xfig_get_object_bbox (obj)
{
   return (@obj.get_bbox_fun)(obj.object);
}

private define begin_render_as_compound (obj, fp)
{
   variable x0, x1, y0, y1, z0, z1, x, y;

   (x0, x1, y0, y1, z0, z1) = xfig_get_object_bbox (obj);
   (x, y) = xfig_project_to_xfig_plane (vector ([x0,x0,x0,x0,x1,x1,x1,x1],
						[y0,y0,y1,y1,y0,y0,y1,y1],
						[z0,z1,z0,z1,z0,z1,z0,z1]));
   x = xfig_convert_units (x);
   y = xfig_convert_units (y);
   xfig_write (fp, sprintf ("6 %d %d %d %d\n", min(x), min(y), max(x), max(y)));
}

private define end_render_as_compound (obj, fp)
{
   xfig_write (fp, "-6\n");
}


%!%+
%\function{xfig_render_object}
%\synopsis{Render an object to a device}
%\usage{xfig_render_object (obj, device)}
%\description
%  This function renders the specified object to a specified device.
%  If the device parameter is a string, then a device will be opened with 
%  the specified name.
%\seealso{xfig_create_file, xfig_close_file}
%!%-
define xfig_render_object (obj, dev)
{
   variable rac;
   variable do_close = 0;
   if (obj == NULL)
     return;
   if (typeof (dev) == String_Type)
     {
	do_close = 1;
	dev = xfig_create_file (dev);
     }
   variable fp = dev;
   if (typeof (dev) == Struct_Type)
     fp = dev.fp;
   
   rac = ((obj.flags & XFIG_RENDER_AS_COMPOUND)
	  and (obj.object != NULL) 
	  and (length (obj.object) != 0));   %  FIXME: add a count objects method

   if (rac)
     begin_render_as_compound (obj, fp);

   (@obj.render_fun) (obj.object, fp);
   
   if (rac) 
     end_render_as_compound (obj, fp);
   if (do_close) 
     xfig_close_file (dev);
}

private define translate_compound (c, dX)
{
   foreach (c)
     {
	variable obj = ();
	(@obj.translate_fun)(obj.object, dX);
     }
}

private define rotate_compound (c, axis, theta)
{
   foreach (c)
     {
	variable obj = ();
	(@obj.rotate_fun)(obj.object, axis, theta);
     }
}

private define scale_compound (c, sx, sy, sz)
{
   foreach (c)
     {
	variable obj = ();
	(@obj.scale_fun)(obj.object, sx, sy, sz);
     }
}

private define set_attr_compound (c, attr, value)
{
   foreach (c)
     {
	variable obj = ();
	(@obj.set_attr_fun)(obj.object, attr, value);
     }
}

private variable Infinity = 1e38;
private define get_bbox_compound (c)
{
   variable x0, x1, y0, y1, z0, z1;
   variable xmin = Infinity, ymin = Infinity, zmin = Infinity;
   variable xmax = -Infinity, ymax = -Infinity, zmax = -Infinity;

   foreach (c)
     {
	variable obj = ();
	(x0, x1, y0, y1, z0, z1) = (@obj.get_bbox_fun)(obj.object);
	if (x0 < xmin) xmin = x0;
	if (x1 > xmax) xmax = x1;
	if (y0 < ymin) ymin = y0;
	if (y1 > ymax) ymax = y1;
	if (z0 < zmin) zmin = z0;
	if (z1 > zmax) zmax = z1;
     }
   return xmin, xmax, ymin, ymax, zmin, zmax;
}

private define render_compound (c, fp)
{
   foreach (c)
     {
	variable obj = ();
	xfig_render_object (obj, fp);
	% (@obj.render_fun)(obj.object, fp);
     }
}

define xfig_new_compound_list ()
{
   variable obj = xfig_new_object ({});
   obj.render_fun = &render_compound;
   obj.rotate_fun = &rotate_compound;
   obj.translate_fun = &translate_compound;
   obj.scale_fun = &scale_compound;
   obj.set_attr_fun = &set_attr_compound;
   obj.get_bbox_fun = &get_bbox_compound;
   obj.flags |= XFIG_RENDER_AS_COMPOUND;
   return obj;
}

define xfig_compound_list_insert (obj, item)
{
   list_insert (obj.object, item);
}

% Usage: c = xfig_new_compound (obj, ...);
define xfig_new_compound ()
{
   variable c = xfig_new_compound_list ();

   %_stk_reverse (_NARGS);
   loop (_NARGS)
     {
	variable obj = ();
	if (obj != NULL)
	  xfig_compound_list_insert (c, obj);
     }
   return c;
}


%!%+
%\function{xfig_justify_object}
%\synopsis{Justify an object at a specified position}
%\usage{xfig_justify_object (obj, X, dX)}
%\description
%  This function moves the object to the specified position X (a vector) 
%  and justifies it at that position according to the offsets specified by
%  the vector \exmp{dX}.  The components of \exmp{dX} are normally in the 
%  range -0.5 to 0.5 and represent offsets relative to the size of the object.
%  If the components of dX are 0, then the object will be centered at \exmp{X}.
%\seealso{xfig_translate_object}
%!%-
define xfig_justify_object (obj, X, dX)
{
   variable x0, x1, y0, y1, z0, z1;
   (x0, x1, y0, y1, z0, z1) = xfig_get_object_bbox (obj);
   
   xfig_translate_object (obj, vector (X.x - 0.5*(x0+x1) - dX.x*(x1-x0),
				       X.y - 0.5*(y0+y1) - dX.y*(y1-y0),
				       X.z - 0.5*(z0+z1) - dX.z*(z1-z0)));
}

% Usage: xfig_new_vbox_compound (o1, o2, ,,, [optional-space]);
define xfig_new_vbox_compound ()
{
   variable objs = __pop_args (_NARGS);
   variable ymin;
   variable y0, y1;
   variable space = 0;

   variable num = length (objs);
   if (0 == is_struct_type (objs[-1].value))
     {
	space = objs[-1].value;
	num--;
	objs = objs[[0:num-1]];
     }

   if (num > 1)
     {
	(,,ymin,,,) = xfig_get_object_bbox (objs[0].value);
	variable v0 = vector (0, ymin, 0);
	foreach (objs[[1:]])
	  {
	     variable obj = ();
	     obj = obj.value;
	     (,,y0,y1,,) = xfig_get_object_bbox (obj);
	     variable v = vector (0, y1+space, 0);
	     variable dv = vector_diff (v0, v);
	     xfig_translate_object (obj, dv);
	     v0 = vector_sum (vector (0, y0, 0), dv);
	  }
     }
   return xfig_new_compound (__push_args (objs));
}

% Usage: xfig_new_hbox_compound (o1, o2, ,,, [optional-space]);
define xfig_new_hbox_compound ()
{
   variable objs = __pop_args (_NARGS);
   variable xmax;
   variable x0, x1;
   variable space = 0;
   
   variable num = length (objs);
   if (0 == is_struct_type (objs[-1].value))
     {
	space = objs[-1].value;
	num--;
	objs = objs[[0:num-1]];
     }

   if (num > 1)
     {
	(,xmax,,,,) = xfig_get_object_bbox (objs[0].value);
	variable v0 = vector (xmax, 0, 0);
	foreach (objs[[1:]])
	  {
	     variable obj = ();
	     obj = obj.value;
	     (x0,x1,,,,) = xfig_get_object_bbox (obj);
	     variable v = vector (x0-space, 0, 0);
	     variable dv = vector_diff (v0, v);
	     xfig_translate_object (obj, dv);
	     v0 = vector_sum (vector (x1, 0, 0), dv);
	  }
     }
   return xfig_new_compound (__push_args (objs));
}


define xfig_object_set_attr (obj, attr, val)
{
   (@obj.set_attr_fun)(obj.object, attr, val);
}

define xfig_set_depth (p, val)
{
   xfig_object_set_attr (p, "depth", val);
}

define xfig_set_line_style (p, val)
{
   xfig_object_set_attr (p, "line_style", val);
}

define xfig_set_thickness (p, val)
{
   xfig_object_set_attr (p, "thickness", val);
}

define xfig_set_pen_color (p, val)
{
   if (typeof (val) == String_Type)
     val = xfig_lookup_color (val);
   xfig_object_set_attr (p, "pen_color", val);
}

define xfig_set_fill_color (p, val)
{
   if (typeof (val) == String_Type)
     val = xfig_lookup_color (val);
   xfig_object_set_attr (p, "fill_color", val);
}

define xfig_set_pen_style (p, val)
{
   xfig_object_set_attr (p, "pen_style", val);
}

define xfig_set_area_fill (p, val)
{
   xfig_object_set_attr (p, "area_fill", val);
}

define xfig_set_style_val (p, val)
{
   xfig_object_set_attr (p, "style_val", val);
}

define xfig_set_join_style (p, val)
{
   xfig_object_set_attr (p, "join_style", val);
}

define xfig_set_cap_style (p, val)
{
   xfig_object_set_attr (p, "cap_style", val);
}

define xfig_set_radius (p, val)
{
   xfig_object_set_attr (p, "radius", val);
}

define xfig_set_font (p, val)
{
   xfig_object_set_attr (p, "font", val);
}
define xfig_set_font_size (p, val)
{
   xfig_object_set_attr (p, "font_size", val);
}

%Letter (8.5" x 11"),
%Legal (8.5" x 14"),
%Ledger ( 17" x 11"),
%Tabloid ( 11" x 17"),
%A (8.5" x 11"),
%B ( 11" x 17"),
%C ( 17" x 22"),
%D ( 22" x 34"),
%E ( 34" x 44"),
%A4 (21 cm x 29.7cm),
%A3 (29.7cm x 42 cm),
%A2 (42 cm x 59.4cm),
%A1 (59.4cm x 84.1 cm),
%A0 (84.1 cm x 118.9cm),
%B5 (18.2cm x 25.7cm) 
define xfig_set_paper_size (paper)
{
   XFig_Header.papersize = paper;
}


% Use CM as the default system
xfig_use_cm ();
xfig_set_eye (1e6, 0, 0);
xfig_set_paper_size ("Letter");
