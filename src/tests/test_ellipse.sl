() = evalfile (path_concat (path_dirname(__FILE__), "setup.sl"));

define slsh_main ()
{
   variable xfig = xfig_create_file (path_concat (OutDir, "ellipse_rotate.eps"));
   variable theta;
   _for theta (0, 90, 15)
   {
     variable col = theta/15 - 1;
     variable e = xfig_new_ellipse (2+theta/15, 1; color=col);
     e.rotate (vector (0,0,1), theta/180.*PI);
     e.render (xfig);
     xfig_new_polyline(e.X.x[[0,1]], e.X.y[[0,1]]; color=col).render(xfig);
   }
   xfig_close_file (xfig);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   xfig = xfig_create_file (path_concat (OutDir, "ellipse_BoundingBox.eps"));

   variable a=5, b=2; theta = PI/3;
   e = xfig_new_ellipse (a, b);
   e.rotate (vector (0,0,1), theta);

   xfig_justify_object (e, vector (0,0,0), vector (0,0,0));
   e.render (xfig);
   xfig_new_polyline(e.X.x[[0,1]], e.X.y[[0,1]]; line=0).render(xfig);
   xfig_new_polyline(e.X.x[[0,2]], e.X.y[[0,2]]; line=1).render(xfig);

   xfig_new_polyline([-.2,.2,0,0,0], [0,0,0,-.2,.2]).render(xfig);

   variable xmin, xmax, ymin, ymax;
   (xmin, xmax, ymin, ymax, ,) = e.get_bbox();
   xfig_new_polyline([xmin,xmax,xmax,xmin], [ymin,ymin,ymax,ymax]; closed, line=2).render(xfig);

   xfig_close_file (xfig);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   xfig = xfig_create_file (path_concat (OutDir, "ellipse_scale.eps"));
   e.translate (vector (-e.X.x[0], -e.X.y[0], -e.X.z[0]));
   e.render (xfig);
   xfig_new_polyline(e.X.x[[0,1]], e.X.y[[0,1]]).render(xfig);
   xfig_new_polyline(e.X.x[[0,2]], e.X.y[[0,2]]).render(xfig);
   variable t = [0:2*PI:#1000];
   xfig_new_polyline(cos(theta)*a*cos(t) - sin(theta)*b*sin(t),
		     sin(theta)*a*cos(t) + cos(theta)*b*sin(t)
		     ; line=1, color="red").render(xfig);


   variable sx=2, sy=.5; col = "blue4";
   xfig_new_polyline(sx*e.X.x[[0,1]], sy*e.X.y[[0,1]]; line=1, color="red").render(xfig);
   xfig_new_polyline(sx*e.X.x[[0,2]], sy*e.X.y[[0,2]]; line=1, color="red").render(xfig);
   xfig_new_polyline(sx*(cos(theta)*a*cos(t) - sin(theta)*b*sin(t)),
                     sy*(sin(theta)*a*cos(t) + cos(theta)*b*sin(t))
		     ; line=1, color="red").render(xfig);

   e.scale (sx, sy);
   e.set_pen_color (col);
   e.render (xfig);
   xfig_new_polyline(e.X.x[[0,1]], e.X.y[[0,1]]; color=col).render(xfig);
   xfig_new_polyline(e.X.x[[0,2]], e.X.y[[0,2]]; color=col).render(xfig);

   xfig_close_file (xfig);
}
