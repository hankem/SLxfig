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

private define gaussian_pdf (x, sigma)
{
   return exp(-0.5*(x/sigma)^2)/sigma/sqrt(2*PI);
}

define slsh_main ()
{
   variable mu = 5, sigma = 1;
   variable data = mu + rand_gauss (sigma, 100);
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
   w.plot (x,y, dx, {dy, 0.75*dy}; 
	   line=1, color="blue", 
	   sym="diamond", symcolor="blue1", width=3, size=3, fill=10,
	   eb_color="orange");
   w.title ("Example with asymmetric error bars");
   w.xlabel("$\lambda$ [\AA]"R);
   w.ylabel("Counts per bin"R);

   xfig_render_object (w, "errbar.png");
}
