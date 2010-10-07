require ("xfig");

private define new_opaque_box (obj)
{
   variable x0, x1, y0, y1;
   (x0, x1, y0, y1,,) = obj.get_bbox ();
   variable box = xfig_new_polygon (vector([x0, x1, x1, x0, x0],
					   [y0, y0, y1, y1, y0],
					   [0, 0, 0, 0, 0]));
   box.set_pen_color ("white");
   box.set_area_fill (20);
   box.set_fill_color ("white");
   return box;
}

define slsh_main ()
{
   xfig_use_inches ();
   variable
     rmax = 6,
     bigtic = 1, medtic = 0.5*bigtic, smalltic = 0.2*bigtic,
     border = 0.5;
   variable obj = xfig_new_compound_list ();
   variable tics = xfig_new_polyline_list ();
   variable theta;

   _for theta (0, 90, 1)
     {
	variable theta_rad = theta * PI/180.0;
	variable ticsize = smalltic;
	variable draw_label = 0;
	if ((theta mod 5) == 0) ticsize = medtic;
	if ((theta mod 10) == 0)
	  {
	     ticsize = bigtic;
	     draw_label = 1;
	  }
	variable
	  rmin = rmax - ticsize,
	  xs = [rmin, rmax]*sin(theta_rad),
	  ys = -[rmin, rmax]*cos(theta_rad),
	  zs = [0, 0];

	tics.insert (vector (xs, ys, zs));
	if (draw_label)
	  {
	     variable label = xfig_new_text ("$theta"$; size="LARGE");
	     variable dX = 1.0*vector (sin(theta_rad), -cos(theta_rad), 0);
	     xfig_justify_object(label, vector(xs[0], ys[0], 0), dX);
	     variable box = new_opaque_box (label);
	     box.set_depth (10);
	     label.set_depth (0);
	     obj.insert (label);
	     obj.insert (box);
	  }
	if ((theta == 0) || (theta == 90))
	  {
	     xs[0] = -border*sin(theta_rad), ys[0] = border*cos(theta_rad);
	     tics.insert (vector(xs,ys,zs));
	  }
     }
   tics.set_thickness (3);
   tics.set_depth (20);
   obj.insert (tics);

   % Now draw a circle around the origin
   variable circle = xfig_new_ellipse (border*0.25, border*0.25);
   % and add the border
   variable
     xmin = -border, xmax = rmax+border,
     ymin = -rmax-border, ymax = border;
   box = xfig_new_polygon (vector([xmin, xmax, xmax, xmin, xmin],
				  [ymin, ymin, ymax, ymax, ymin],
				  [0, 0, 0, 0, 0]));
   obj.insert (circle);
   obj.insert (box);
   obj.render ("inclinometer.ps");
}
