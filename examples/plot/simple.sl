require ("xfig");
public define slsh_main ()
{
   variable x = 10^[-1:1.5:#200];
   variable y = sin (1/x)*exp(-x);

   variable w = xfig_plot_new ();
   w.plot (x, y;logx);
   w.xlabel ("Time[s]"R);
   w.ylabel ("Voltage [mV]"R);
   w.title ("Simple Example");
   w.render("simple.png");
}
