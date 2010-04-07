import ("gcontour");

private define do_gcontour_callback (xvals, yvals, zlevel, s)
{
   return (@s.fun)(xvals, yvals, zlevel, __push_list (s.args));
}

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
define gcontour ()
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

   return _gcontour (img, zvals, &do_gcontour_callback, 
		     struct { fun=fun, args=args });
}

private define gcontour_compute_callback (xvals, yvals, zlevel, contours)
{
   variable s = contours[zlevel];
   list_append (s.x_list, xvals);
   list_append (s.y_list, yvals);
}

%!%+
%\function{gcontour_compute}
%\usage{Struct_Type[] gcontour_compute(img, levels)}
%\description
% This function takes a 2d array of numbers (\exmp{img}) and an array of
% array of N contour-levels (\exmp{levels}) and returns the
% corresponding contours in the form of an array of N structures.
% Each structure contains the contour lines for the corresponding level
% via the fields \exmp{x_list} and \exmp{y_list}.
% As the names indicate, the values of these fields are lists.  Each
% element of the x_list contains the image x coordinate of the
% contour.  Similarly each element of the y_list field is an array of
% image y coordinates.
%\seealso{gcontour}
%!%-
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
