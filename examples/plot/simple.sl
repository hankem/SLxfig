require ("xfig");
public define slsh_main ()
{
   variable t = [0:5:0.1];
   variable y = cos (2*PI*t)*exp(-t);
   variable w = xfig_plot_new ();
   xfig_plot_define_world (w, t, y);
   xfig_plot_add_x_axis (w, 0, "Time [s]"R);
   xfig_plot_add_y_axis (w, 0, "Voltage [mV]"R);
   xfig_plot_lines (w, t, y);
   xfig_plot_title (w, "Simple Example");
   xfig_render_object (w, "simple.png");
}
