require ("xfig");
require ("rand");

private define f2c (f)
{
   return 5.0/9.0 * (f-32.0);
}

define slsh_main ()
{
   variable w = xfig_plot_new ();
   w.xlabel ("Length [inches]");
   w.x2label ("Length [cm]");
   w.ylabel ("Temperature [F]");
   w.y2label ("Temperature [C]");
   
   % Fake some data
   variable npts = 30;
   variable sigma_l = 0.2;
   variable sigma_t = 20.0;
   variable lengths = [3.0:12.0:#npts] + rand_gauss (sigma_l, npts);
   variable temps = [-200:120:#npts] + rand_gauss (sigma_t, npts);

   w.world1 (lengths, temps);
   w.world2 (2.54*lengths, f2c(temps));
   
   % For fun, plot the data as inches-vs-C, which is world12
   w.plot (lengths, f2c(temps), sigma_l, 5.0/9.0*sigma_t; 
	   world12, sym="x", color="blue");
   
   w.shade_region (6, 8, 0, 1; world10, fillcolor="black", fill=5);
   
   w.render ("world.png");
}
