require ("xfig");
require ("png");
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

private define make_hist_image (x, h, xmin, xmax, ymin, ymax, color)
{
   variable w = xfig_plot_new ();
   w.world (xmin, xmax, ymin, ymax);
   w.axes (; off);
   w.hplot (x, h; fill=20, color=color);
   w.plot ([xmin, xmax], [ymin, ymax]; sym="point");   %  registration marks
   variable tmp = "tmp.png";
   w.render (tmp);
   variable img = png_read (tmp);
   ()=remove (tmp);
   return img;
}

public define slsh_main ()
{
   variable mu = 100, sigma = 15;
   variable data1 = mu + rand_gauss (sigma, 10000);
   variable data2 = 10 + mu + rand_gauss (sigma, 10000);
   variable all_data = [data1, data2];

   variable x = [int(min(all_data)):1+int(max(all_data)):1];
   variable h1 = hist1d (data1, x)/(1.0*length(data1));
   variable h2 = hist1d (data2, x)/(1.0*length(data2));

   variable xmin = x[0], xmax = x[-1], ymin = 0, ymax = max([h1,h2]);
   variable img1 = make_hist_image (x, h1, xmin, xmax, ymin, ymax, "red");
   variable img2 = make_hist_image (x, h2, xmin, xmax, ymin, ymax, "blue");

   variable img1_r = png_rgb_get_r (img1);
   variable img1_g = png_rgb_get_g (img1);
   variable img1_b = png_rgb_get_b (img1);
   variable img2_r = png_rgb_get_r (img2);
   variable img2_g = png_rgb_get_g (img2);
   variable img2_b = png_rgb_get_b (img2);

   variable w1 = 0.5 + img1_r*0.0;
   variable i = where ((img1 == 0xFFFFFF) and (img2 != 0xFFFFFF));
   w1[i] = 0.0;
   i = where ((img2 == 0xFFFFFF) and (img1 != 0xFFFFFF));
   w1[i] = 1.0;
   variable w2 = 1.0 - w1;

   variable img12_r = typecast (w1*img1_r + w2*img2_r, UChar_Type);
   variable img12_g = typecast (w1*img1_g + w2*img2_g, UChar_Type);
   variable img12_b = typecast (w1*img1_b + w2*img2_b, UChar_Type);
   variable img12 = (img12_r shl 16)|(img12_g shl 8)|(img12_b);
   variable png = "tmp.png";
   png_write (png, img12);

   variable w = xfig_plot_new ();
   w.world (xmin, xmax, ymin, ymax);
   w.plot_png (png);
   w.xlabel ("IQ");
   w.ylabel ("Probability [bin$^{-1}$]");
   w.title (`$\mu=100;\sigma=15$ vs. $\mu=110;\sigma=15$`);
   w.render("overlay.png");
   ()=remove (png);
}
