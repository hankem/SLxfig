() = evalfile (path_concat (path_dirname(__FILE__), "setup.sl"));

define slsh_main ()
{
   variable x = xfig_plot_new ();
   variable base = path_basename_sans_extname (__FILE__);
   x.world (0, 10, 0, 100);
   x.plot ([0:10], dup^2);
   x.render (path_concat (OutDir, base+"_default.eps"));
   variable cx, cy;
   foreach cx ([0,1])
     foreach cy ([0,1])
       {
	 x.title ("cx=$cx, cy=$cy"$);
	 x.x1axis (; ticlabels_confine=cx);
	 x.y1axis (; ticlabels_confine=cy);
	 x.render (path_concat (OutDir, sprintf ("%s_%d%d.eps", base, cx, cy)));
       }
}
