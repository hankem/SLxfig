require ("xfig");
require ("rand");
try
{
   require ("histogram");
}
catch IOError:
{
   () = fprintf (stderr, "This example requires the histogram module\n");
   exit (0);
}

private define gauss_pdf (x, sigma)
{
   return 1.0/sqrt(2*PI*sigma^2) * exp(-0.5*x^2/sigma^2);
}

public define slsh_main ()
{
   variable mu = 100, sigma = 15, dx = 1.0;
   variable data = mu + rand_gauss (sigma, 10000);
   variable x = [min(data):max(data):dx];
   variable h = hist1d (data, x)/(dx*length(data));
   variable w = xfig_plot_new ();
   w.world (x,h);
   w.hplot (x, h; fillcolor="red", fill=20);
   h = gauss_pdf (x-mu,sigma);
   w.plot (x,h; color="blue");
   w.xlabel ("IQ");
   w.ylabel ("Probability [bin$^{-1}$]");
   w.title (`$\mu=100;\sigma=15$`);
   w.render ("histplt.png");
}
