require ("xfig");
public define slsh_main ()
{
   variable t = [0:5:#12];
   variable y = cos (2*PI*t)*exp(-t);

   variable w = xfig_plot_new ();
   w.world (-1, 6, -1.5, 1.5);
   w.xaxis (;color="green3", width=1);
   w.yaxis (;color="green3", width=1);
   variable dy = 0.2;
   _for (0, length (t)-1, 1)
     {
	variable i = ();
	w.plot (t[i], y[i], dy; size=1, width=1,
		line=0, sym="point", color="blue", fill=20, fillcolor="red");
     }
   w.title (w, "A plot with symbols");
   w.xlabel ("Time [s]"R; color=0xFFCC00, size="Huge");
   w.ylabel ("Voltage [mV]"R);
   w.render ("symbol.png");
}
