require ("xfig");
require ("png");
require ("gslrand");
require ("histogram");

private define make_hist_image (x, h, xmin, xmax, ymin, ymax, color)
{
   variable w = xfig_plot_new ();
   w.world (xmin, xmax, ymin, ymax);
   xfig_plot_set_line_color (w, color);
   xfig_plot_shaded_histogram (w, x, h, color, 20);
   w.plot ([xmin, xmax], [ymin, ymax]; line=0, sym="point");
   variable tmp = "tmp.png";
   w.render (tmp);
   variable img = png_read (tmp);
   ()=remove (tmp);
   return img;
}

   
public define slsh_main ()
{
   variable mu = 100, sigma = 15;
   variable data = mu + ran_gaussian (sigma, 10000);
   variable x = [int(min(data)):1+int(max(data)):1];
   variable h = hist1d (data, x)/(1.0*length(data));
   variable xmin = min(x), xmax = max(x), ymin = 0, ymax = max(h);

   variable img1 = make_hist_image (x, h, xmin, xmax, ymin, ymax, "red");

   data = 10 + mu + ran_gaussian (sigma, 10000);
   x = [int(min(data)):1+int(max(data)):1];
   h = hist1d (data, x)/(1.0*length(data));
   variable img2 = make_hist_image (x, h, xmin, xmax, ymin, ymax, "blue");

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
   w.world (xmin, ymin, xmax, ymax);
   xfig_plot_png (w, png);
   w.xlabel ("IQ");
   w.ylabel ("Probability [bin$^{-1}$]");
   w.title ("IQ; $\sigma=100;\mu=15$"R);
   w.render("overlay.png");
}
