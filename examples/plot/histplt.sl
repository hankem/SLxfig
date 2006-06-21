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
   xfig_plot_define_world (w, x, h);
   xfig_plot_add_x_axis (w, 0, "IQ");
   xfig_plot_add_y_axis (w, 0, "Probability [bin$^{-1}$]");
   xfig_plot_shaded_histogram (w, x, h, "red", 20);
   h = gaussian_pdf (x-mu,sigma);
   xfig_plot_lines (w, x, h);
   xfig_plot_title (w, "IQ; $\sigma=100;\mu=15$"R);
   xfig_render_object (w, "histplt.png");
}
