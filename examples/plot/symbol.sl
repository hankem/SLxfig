require ("xfig");
public define slsh_main ()
{
   variable t = [0:5:0.1];
   variable y = cos (2*PI*t)*exp(-t);
   variable w = xfig_plot_new ();
   xfig_plot_define_world (w, t, y);
   xfig_plot_add_x_axis (w, 0, "Time [s]"R);
   xfig_plot_add_y_axis (w, 0, "Voltage [mV]"R);
   %xfig_plot_symbols (w, t, y, "triangle-down");
   xfig_plot_set_point_size (w, 2);
   xfig_plot_set_point_color (w, "blue");
   xfig_plot_symbols (w, t, y, "diamond");
#iffalse
   xfig_plot_set_point_size (w, 1);
   xfig_plot_symbols (w, t, y, "square");
   xfig_plot_set_point_size (w, 2);
   xfig_plot_symbols (w, t, y-0.1, "square");
   xfig_plot_set_point_size (w, 3);
   xfig_plot_symbols (w, t, y-0.2, "square");
   xfig_plot_set_point_size (w, 4);
   xfig_plot_symbols (w, t, y-0.3, "square");
#endif
   xfig_plot_title (w, "Simple Example");
   xfig_render_object (w, "symbol.png");
}
