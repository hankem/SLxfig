require ("xfig");
require ("gslrand");

public define slsh_main ()
{
   variable w = xfig_plot_new (14,14);
   variable x = ran_gaussian (1.0, 10000);
   variable y = ran_gaussian (1.0, 10000);
   w.world (-5,5,-5,5);
   w.plot (x,y;sym="point",size=0.1);
   w.add_object (xfig_new_text ("\\large points"), 0.25, 0.75 ; world00);
   w.render ("scatter.png");
}
