() = evalfile (path_concat (path_dirname(__FILE__), "setup.sl"));

define slsh_main ()
{
   variable N = 10000;

   variable a = xfig_plot_new();
   a.world (0, 1,   1,   9);
   a.world2(0, 1, N+1, N+9);
   a.plot(0.5, 5, 1);
   a.ylabel ("A$_1$");
   a.y2label("A$_2$");

   variable b = xfig_plot_new();
   b.world (0, 1, N+1, N+9);
   b.world2(0, 1,   1,   9);
   b.plot(0.5, N+5, 1);
   b.ylabel("B$_1$");
   b.y2label("B$_2$");

   xfig_multiplot(a, b).render(path_concat(OutDir,"xfig_multiplot-align_ylabels=0.eps")
			       ; align_ylabels=0);
   xfig_multiplot(a, b).render(path_concat(OutDir,"xfig_multiplot-align_ylabels=1.eps"));
}
