require ("xfig");
require ("gslrand");
require ("histogram");
public define slsh_main ()
{
   variable mu = 100, sigma = 15, dx = 1.0;
   variable data = mu + ran_gaussian (sigma, 10000);
   variable x = [min(data):max(data):dx];
   variable h = hist1d (data, x)/(dx*length(data));
   variable w = xfig_plot_new ();
   w.world (x,h);
   w.hplot (x, h; fillcolor="red", fill=20);
   h = gaussian_pdf (x-mu,sigma);
   w.plot (x,h; color="blue");
   w.xlabel ("IQ");
   w.ylabel ("Probability [bin$^{-1}$]");
   w.title ("IQ; $\sigma=100;\mu=15$"R);
   w.render ("histplt.png");
}
