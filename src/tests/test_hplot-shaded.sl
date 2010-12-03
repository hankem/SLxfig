() = evalfile (path_concat (path_dirname(__FILE__), "setup.sl"));

define slsh_main ()
{
  variable xlo = [0,1,2,3,4,5,6,7,8,9];
  variable y   = [1,0,3,6,9,8,4,2,3,1];
  variable p = xfig_plot_new();
  p.world(0, 10, 0, 10);
  p.hplot(xlo, y; fill=5);
  p.render (path_concat (OutDir, "hplot-shaded.eps"));
}
