require ("xfig");
public define slsh_main ()
{
   variable t = [0:5:#1000];
   variable y = cos (2*PI*t)*exp(-t);
   variable w1 = xfig_plot_new (14, 6);
   variable w2 = xfig_plot_new (14, 3);
   variable w1w2 = xfig_new_vbox_compound (w1, w2, 0);

   w1.world (t, y;xlog);
   w1.x1axis(;ticlabels=0);
   w1.plot (t, y; color="blue3");
   w1.plot (t[[::10]], y[[::10]]; sym="diamond", color="green2", line=0, fill=1);
   w1.title ("\Huge Two subplots"R);

   y = cos (2*PI*t);
   w2.world (t, y;xlog);
   w2.xlabel("\bf Time [s]"R);
   w2.plot (t, y);

   w1.ylabel("\bf Damped Oscillation"R);
   w2.ylabel("\bf\begin{center}Undamped\\Oscillation\end{center}"R);


   w1w2.render ("subplot.png");
}
