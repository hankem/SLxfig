import ("gcontour");

if (0 == is_defined ("Polygon_List_Type"))
typedef struct
{
   polygons
}
Polygon_List_Type;
  
define polygon_list_new ()
{
   variable ndims = 2;
   if (_NARGS == 1)
     ndims = ();
   
   variable c = @Polygon_List_Type;
   variable polygons = List_Type[ndims];
   _for (0, ndims-1, 1)
     {
	variable i = ();
	polygons[i] = {};
     }
   c.polygons = polygons;
   return c;
}

define polygon_list_put ()
{
   variable args = __pop_args (_NARGS-1);
   variable c = ();
   variable polygons = c.polygons;
   variable n = length (polygons);
   if (n != length (args))
     throw InvalidParmError, "A $n-d polygon is required"$;
   
   _for (0, n-1, 1)
     {
	variable i = ();
	list_append (polygons[i], args[i].value);
     }
}

define polygon_list_get (c, n)
{
   variable polygons = c.polygons;
   _for (0, length (polygons)-1, 1)
     {
	variable i = ();
	polygons[i][n];
     }
}

define polygon_list_length (c)
{
   return length (c.polygons[0]);
}

%!%+
%\function{polygon_list_apply}
%\synopsis{Apply a function to a polygon list}
%\usage{polygon_list_apply (plist, fun [,fun_args...])}
%\description
% This function will call the specified function for each polygon in the
% list using
%#v+
%   fun (x,y,fun_args...);
%#v-
%\seealso{polygon_list_bbox}
%!%-
define polygon_list_apply ()
{
   variable args = __pop_args (_NARGS-2);
   variable fun = ();
   variable c = ();

   variable n = polygon_list_length (c);
   _for (0, n-1, 1)
     {
	variable i = ();
	variable x, y;
	(@fun)(polygon_list_get (c, i), __push_args(args));
     }
}

private define bbox_callback ()
{
   variable maxs = ();
   variable mins = ();
   _for (length (mins)-1, 0, -1)
     {
	variable i = ();
	variable x_i = ();
	variable min_x = min (x_i);
	variable max_x = max (x_i);
	if (min_x < mins[i])
	  mins[i] = min_x;
	if (max_x > maxs[i])
	  maxs[i] = max_x;
     }
}


%!%+
%\function{polygon_list_bbox}
%\synopsis{Get the bounding box of a polygon list}
%\usage{(mins, maxs) = polygon_list_bbox (plist)}
%\description
%  This function returns two arrays giving the bounding box of the specified
%  polygon list.
%\seealso{polygon_list_apply}
%!%-
define polygon_list_bbox (c)
{
   variable n = length (c.polygons);
   variable mins = _Inf[Int_Type[n]];
   variable maxs = -_Inf[Int_Type[n]];
  
   polygon_list_apply (c, &bbox_callback, mins, maxs);
   return mins, maxs;
}

private define do_gcontour_callback (xvals, yvals, zlevel, s)
{
   return (@s.fun)(xvals, yvals, zlevel, __push_args (s.args));
}

define gcontour ()
{
   variable nargs = _NARGS;
   variable args = NULL;
   if (nargs > 3)
     {
	args = __pop_args (nargs - 3);
	nargs = 3;
     }
   if (nargs != 3)
     usage ("gcontour (2d-array, 1d-levels, &callback-fun [, callback-args...])");

   variable img, zvals, fun;
   (img, zvals, fun) = ();
   
   if (args == NULL)
     return _gcontour (img, zvals, &fun);

   variable s = struct 
     {
	fun, args
     };
   s.fun = fun;
   s.args = args;
   _gcontour (img, zvals, &do_gcontour_callback, s);
}

private define gcontour_compute_callback (xvals, yvals, zlevel, list)
{
   polygon_list_put (list[zlevel], xvals, yvals);
}

% This function returns an array of lists.  Each list in the array contains
% the contours for the corresponding z level.  Each list element contains
% an array of 2 arrays.  So, the 3rd contour for the 5th zlevel is given
% by
%     icoords = contour[5][3][0];
%     jcoords = contour[5][3][1];
define gcontour_compute ()
{
   if (_NARGS != 2)
     usage ("contour_list = %s (2d-array, 1d-levels)", _function_name);
   
   variable img, zvals;
   (img, zvals) = ();
   
   variable nz = length (zvals);
   variable contours = Struct_Type[nz];
   _for (0, nz-1, 1)
     {
	variable i = ();
	contours[i] = polygon_list_new (2);
     }
   _gcontour (img, zvals, &gcontour_compute_callback, contours);
   return contours;
}
