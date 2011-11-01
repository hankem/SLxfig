() = evalfile (path_concat (path_dirname(__FILE__), "setup.sl"));

define slsh_main ()
{
   variable w = xfig_plot_new();
   w.world1(0, 2, 1, 100; ylog);
   w.world2(0, 2, 0, 2; xticlabels=0);
   w.xlabel(`$x$`);
   w.ylabel(`$y=10^x$`);
   w.y2label(`$\log_{10}(y)$`);

   variable x = [0:2:#100];
   w.plot(x, 10^x);
   w.render (path_concat (OutDir, "world1log_world2lin.eps"));
}
