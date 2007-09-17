require ("xfig");
require ("gslrand");
require ("histogram");
public define slsh_main ()
{
   variable mu = 100, sigma = 15;
   variable data = mu + ran_gaussian (sigma, 10000);
   variable x = [min(data):max(data):1];
   variable h = hist1d (data, x)/(1.0*length(data));
   variable w = xfig_plot_new ();
   w.world (x,h);
   xfig_plot_shaded_histogram (w, x, h, "red", 20);
   h = gaussian_pdf (x-mu,sigma);
   w.plot (x,h);
   w.xlabel ("IQ");
   w.ylabel ("Probability [bin$^{-1}$]");
   w.title ("IQ; $\sigma=100;\mu=15$"R);
   w.render ("histplt.png");
}
