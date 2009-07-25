require ("xfig");
require ("png");

try
{
   require ("maplib");
}
catch IOError:
{
   () = fprintf (stderr, "This example requires the maplib module\n");
   exit (0);
}

static define func (x, y)
{
   (x, y) = maplib_meshgrid (x, y);
   return 3*(1-x)^2*exp(-x^2 - (y+1)^2) - 10*(x/5 - x^3 - y^5)*exp(-x^2-y^2)
     -0.5*exp(-(x+1)^2 - y^2);
}

define slsh_main ()
{
   variable x = [-3:3:0.05];
   variable y = [-3:3:0.05];
   variable z = func (x, y);

   variable colormap = "drywet";
   png_write_flipped ("tmp1.png", png_gray_to_rgb (z, colormap));
   variable scale = png_gray_to_rgb (_reshape([0:255],[256,1]), colormap);
   png_write_flipped ("tmp2.png", scale);

   variable width = 14, height = 14;
   variable w1 = xfig_plot_new (width, height);
   w1.world(x, y);
   w1.plot_png ("tmp1.png");
   w1.xlabel ("$x$"; size="Large");
   w1.ylabel ("$y$"; size="Large");
   w1.title ("$f(x,y)=3(1-x)^2 e^{-x^2-(y+1)^2} +\ldots$"R; size="Large",color="blue");

   variable w2 = xfig_plot_new (1, height);
   w2.world (0, 1, min(z), max(z));
   w2.xaxis (;off);
   w2.y1axis (;off);
   w2.y2axis (;on);
   w2.y2label ("$f(x,y)$");
   w2.plot_png ("tmp2.png");

   xfig_new_hbox_compound (w1, w2, 2).render ("image.png");
   () = remove ("tmp1.png"); () = remove ("tmp2.png");
}

