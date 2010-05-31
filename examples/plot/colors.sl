require ("xfig");

public define slsh_main ()
{
   variable w = xfig_plot_new (14, 20);
   variable color;
   variable ncolors = 33;
   variable dy = 1.0/(ncolors+1);
   variable y = 1.0;

   _for color (0, ncolors-1, 1)
     {
	y -= dy;
	w.plot ([0.1, 0.5], [y, y]; width=6, color=color, world00);
	variable info = xfig_get_color_info (color);
	if (info == NULL)
	  continue;
	xfig_plot_text (w, sprintf ("%3d %s", color, info.name), 0.6, y, -0.5, 0; world00);
     }
   w.render ("colors.png");
}
