require ("xfig");
public define slsh_main ()
{
   variable t = [0:5:0.01];
   variable y = cos (2*PI*t)*exp(-t);
   variable w1 = xfig_plot_new (14, 4.5);
   xfig_plot_define_world (w1, t, y);
   xfig_plot_add_x_axis (w1, 0, NULL, 0);
   xfig_plot_add_y_axis (w1, 0, "\bf Damped Oscillation"R);
   xfig_plot_lines (w1, t, y);
   xfig_plot_set_point_size (w1, 5);
   xfig_plot_set_point_color (w1, "green");
   xfig_plot_points (w1, t[[::10]], y[[::10]]);
   xfig_plot_title (w1, "\Huge Two subplots"R);

   y = cos (2*PI*t);
   variable w2 = xfig_plot_new (14, 2);
   xfig_plot_define_world (w2, t, y);
   xfig_plot_add_x_axis (w2, 0, "\bf Time [s]"R);
   xfig_plot_add_y_axis (w2, 0, "\bf\begin{center}Undamped\\Oscillation\end{center}"R);
   xfig_plot_lines (w2, t, y);
   
   xfig_render_object (xfig_new_vbox_compound (w1, w2, 0), "subplot.png");
}
