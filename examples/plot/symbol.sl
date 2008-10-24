require ("xfig");
require ("rand");

public define slsh_main ()
{
   variable w = xfig_plot_new ();
   variable symbols = xfig_plot_get_symbol_names ();
   variable num = length (symbols);

   w.world (0, 1, 0, num+1);

   w.xaxis (;color="green3", width=2);
   w.yaxis (;color="green3", width=2);
   variable color = "blue";
   variable dx = 0.1;
   _for (0, num-1, 1)
     {
	variable i = ();
	variable sym = symbols[i];
	variable text = xfig_new_text (sym; size="Large");
	w.plot (0.25, i+1; sym=sym, size=1, width=1, color=color, 
		fill=20, fillcolor=color);
	w.add_object (text, 0.5, i+1);
	w.plot (0.8+dx, i+1; sym=sym, size=3, width=1, color="red");
	dx = -dx;
     }
   w.title (w, "A plot with symbols");
   w.xlabel ("Time [s]"R; color=0xFFCC00, size="Huge");
   w.ylabel ("Voltage [mV]"R);
   w.render ("symbol.png");
}
