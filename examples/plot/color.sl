require ("xfig");

public define slsh_main ()
{
   variable t = 10^[-1:1:#20];
   variable y = cos (2*PI*t)*exp(-t);
   variable dy = 0.2 + 0.1*abs(y);

   variable w = xfig_plot_new (14, 10);
   w.title("Example with colors and fonts"; color="red4", size="Huge");
   w.world (0.09, 12, -1.0, 1.0; xlog);
   w.axis (;grid=1, major_line=1, minor_line=2);
   w.xaxis (;color="magenta4",major_color="green2");
   w.yaxis (;color="magenta4");
   w.x1axis (;ticlabel_color="blue2");
   w.y1axis (;ticlabel_color="green2");
   w.plot (t, y, dy; line=2, color="red3",
	   sym="triangle", symcolor="blue", symsize=2, fill=20, eb_color="green4");
   w.xlabel ("Time [s]"R; color="cyan4", size="large");
   w.ylabel ("Voltage [mV]"; color="red");
   w.x2label ("This is the x2label";size="large", color="orange");
   xfig_new_color ("aquamarine3", (102 shl 16)|(205 shl 8)|170);

   variable text = xfig_new_text ("Equation: \bf $e^{-t}\cos(2\pi t)$"R;
				  color="black", size="Huge", style="sc");
   text.set_depth(1);
   w.add_object (text, 10, 0.75, 0.5, 0);
   w.render ("color.png");
}
   
   
