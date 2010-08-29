() = evalfile (path_concat (path_dirname(__FILE__), "setup.sl"));

define set_labels(x, text)
{
   x.xlabel  ("x1-label"+text);
   x.ylabel  ("y1-label"+text);
   x.x2label ("x2-label"+text);
   x.y2label ("y2-label"+text);
}

define slsh_main ()
{
   variable x = xfig_plot_new();
   set_labels(x, " before plotting");
   x.render (path_concat (OutDir, "plot_axis-label_1.eps"));

   x.plot ([0:10], dup^2);
   set_labels(x, " after plotting");
   x.render (path_concat (OutDir, "plot_axis-label_2.eps"));

   set_labels(x, ", again overwritten");
   x.render (path_concat (OutDir, "plot_axis-label_3.eps"));
}
