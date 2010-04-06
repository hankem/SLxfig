import ("gcontour");

private define do_gcontour_callback (xvals, yvals, zlevel, s)
{
   return (@s.fun)(xvals, yvals, zlevel, __push_list (s.args));
}

define gcontour ()
%!%+
%\function{gcontour}
%\synopsis{}
%\usage{gcontour(img, levels, &callback_fun [, callback_args...]);}
%\description
% \exmp{img} is a 2d-array of numbers, \exmp{levels} is an array of contour-levels,
% and \exmp{callback_fun} is a callback function that will be called as
%#v+
%   callback_fun(x, y, iz [, callback_args...]);
%#v-
% for each contour line at the level \exmp{levels[iz]}
% with the image coordinates \exmp{x} and \exmp{y}.
%\seealso{gcontour_compute}
%!%-
{
   variable nargs = _NARGS;
   variable args = NULL;
   if (nargs > 3)
     {
	args = __pop_list (nargs - 3);
	nargs = 3;
     }
   if (nargs != 3)
     usage ("gcontour (2d-array, 1d-levels, &callback-fun [, callback-args...])");

   variable img, zvals, fun;
   (img, zvals, fun) = ();
   
   if (args == NULL)
     return _gcontour (img, zvals, fun);
   _gcontour (img, zvals, &do_gcontour_callback, struct { fun=fun, args=args });
}

private define gcontour_compute_callback (xvals, yvals, zlevel, contours)
{
   variable s = contours[zlevel];
   list_append (s.x_list, xvals);
   list_append (s.y_list, yvals);
}

define gcontour_compute ()
%!%+
%\function{gcontour_compute}
%\usage{Struct_Type[] gcontour_compute(img, levels)}
%\description
% \exmp{img} is a 2d-array of numbers, \exmp{levels} is an array of contour-levels.
% This return value is an array of the same number of structures.
% Each element contains the contour lines for the corresponding level
% via the fields \exmp{x_list} and \exmp{y_list}.  These lists
% contain the image x and y coordinates of the contours.
%\seealso{gcontour}
%!%-
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
	contours[i] = struct
	  {
	     x_list = {}, y_list = {}
	  };
     }
   _gcontour (img, zvals, &gcontour_compute_callback, contours);
   return contours;
}

$1 = path_concat (path_concat (path_dirname (__FILE__), "help"), "gcontour.hlp");
if (NULL != stat_file ($1))
    add_doc_file ($1);
