require ("xfig");
require ("png");
require ("maplib");

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
   xfig_plot_png (w1, "tmp1.png");
   xfig_plot_define_world (w1, x, y);
   xfig_plot_add_x_axis (w1, 0, "$x$");
   xfig_plot_add_y_axis (w1, 0, "$y$");
   xfig_plot_title (w1, "\Large $f(x,y)=3(1-x)^2 e^{-x^2-(y+1)^2} +\ldots$"R);

   variable w2 = xfig_plot_new (1, height);
   xfig_plot_define_world (w2, 0, 1, min(z), max(z));
   xfig_plot_add_y2_axis (w2, 0, "$f(x,y)$");
   xfig_plot_png (w2, "tmp2.png");

   xfig_render_object (xfig_new_hbox_compound (w1, w2, 2), "image.png");
   () = remove ("tmp1.png"); () = remove ("tmp2.png");
}

