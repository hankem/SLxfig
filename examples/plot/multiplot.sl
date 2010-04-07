require ("xfig");

public define slsh_main ()
{
   variable n = 3;
   variable w = Struct_Type[n];
   variable x = [0:1:#1000];
   variable i;
   variable pow = [0.5, 1, 2];
   _for i (0, n-1, 1)
   {
      w[i] = xfig_plot_new (12, 3);
      w[i].plot (x, x^pow[i]);
      w[i].xlabel ("$x$");
      w[i].ylabel (sprintf ("$n = %g$", pow[i]));
      w[i].title (sprintf ("$y = x^{%g}$", pow[i]));
   }
   variable increasing = 1;
   xfig_multiplot (increasing ? (w[0], w[1], w[2])
		              : (w[2], w[1], w[0])
		   ; title="$y = x^n$"
		  ).render ("multiplot.png");
}
