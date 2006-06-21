require ("xfig");
require ("gslrand");
require ("histogram");

define slsh_main ()
{
   variable mu = 5, sigma = 1;
   variable data = mu + ran_gaussian (sigma, 100);
   variable dx = 0.4;
   variable x = [min(data):max(data):dx];
   variable y = hist1d (data, x);
   variable dy = sqrt (y);

   variable w = xfig_plot_new ();
   xfig_plot_define_world (w, min(x), max(x), 0.9, max(y)*1.1);
   xfig_plot_add_x_axis (w, 0, "$\lambda$ [\AA]"R);
   xfig_plot_add_y_axis (w, 0, "Counts per bin"R);

   variable xx = [mu-5*sigma:mu+5*sigma:0.1*dx];
   variable yy = (dx*length (data)) * gaussian_pdf (xx-mu, sigma);
   xfig_plot_lines (w, xx, yy);

   xfig_plot_set_point_color (w, "blue1");
   xfig_plot_set_point_size (w, 5);
   xfig_plot_set_line_color (w, "blue");
   xfig_plot_set_line_thickness (w, 3);

   x += 0.5*dx;
   xfig_plot_points (w, x, y);
   xfig_plot_erry (w, x, y, dy);
   xfig_plot_errx (w, x, y, 0.5*dx);
   xfig_plot_title (w, "Example with error bars");
   xfig_render_object (w, "errbar.png");
}
