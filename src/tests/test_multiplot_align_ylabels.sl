() = evalfile (path_concat (path_dirname(__FILE__), "setup.sl"));

define slsh_main ()
{
   variable N = 10000;

   variable i;
   _for i (-1, 3, 1)
    {
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

       variable q = i<0 ? struct { title="no align ylabels qualifier set" } : struct { align_ylabels=i };
       variable mp = xfig_multiplot (a, b;; q);
       mp.render (path_concat (OutDir, "xfig_multiplot-align_ylabels=$i.eps"$));
    }
}
