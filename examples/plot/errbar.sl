require ("xfig");
require ("gslrand");
try
{
   require ("histogram");
}
catch IOError:
{
   () = fprintf (stderr, "This example requires the histogram module\n");
   exit (0);
}

define slsh_main ()
{
   variable mu = 5, sigma = 1;
   variable data = mu + ran_gaussian (sigma, 100);
   variable dx = 0.4;
   variable x = [min(data):max(data):dx];
   variable y = hist1d (data, x);
   variable dy = sqrt (y);
   variable xx = [mu-5*sigma:mu+5*sigma:0.1*dx];
   variable yy = (dx*length (data)) * gaussian_pdf (xx-mu, sigma);

   variable w = xfig_plot_new ();
   w.world (min(x), max(x), 0.9, max(y)*1.1);
   w.plot (xx, yy);
   x += 0.5*dx;
   w.plot (x,y, dx, dy ; line=0, sym="diamond", color="blue1", width=3, size=5, fill=10);
   w.title ("Example with error bars");
   w.xlabel("$\lambda$ [\AA]"R);
   w.ylabel("Counts per bin"R);

   xfig_render_object (w, "errbar.png");
}
