require ("xfig");

public define slsh_main ()
{
   variable t = [0:50:0.1];
   variable y = cos (2*PI*t)*exp(-t);
   variable w = xfig_plot_new ();
   xfig_plot_define_world (w, 0.05, 50, -1.0, 1.0);
   xfig_plot_add_x_axis (w, 1, "Time [s]"R);
   xfig_plot_add_y_axis (w, 0, "Voltage [mV]"R);
   xfig_plot_set_point_color (w, "blue");
   xfig_plot_set_point_size (w, 10);
   xfig_plot_points (w, t, y);

   variable font = xfig_make_font ("\\sc", "\\Huge", 0xFF0000);
   variable text = xfig_new_text ("Equation: $e^{-t}\cos(2\pi t)$"R, font);
   xfig_plot_add_object (w, text, 2.5, 0.6, -0.5, 0);
   xfig_render_object (w, "color.png");
}
   
   
