require ("xfig");

public define slsh_main ()
{
   variable color, ncolors = 33;
   variable w = xfig_plot_new (14, 20);
   w.world (0, 1, ncolors, -1);
   w.xaxis(; major=[-1, 2]);
   _for color (0, ncolors-1, 1)
     {
	w.plot ([0.1, 0.5], [color, color]; width=6, color=color);
	variable info = xfig_get_color_info (color);
	if (info == NULL)
	  continue;
	w.xylabel (0.6, color,
		   sprintf (`\verb|#%06X %3d  %s|`, info.rgb, color, info.name),
		   -0.5, 0);
     }
   w.render ("colors.png");
}
