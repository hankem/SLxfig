() = evalfile (path_concat (path_dirname(__FILE__), "setup.sl"));

define slsh_main ()
{
   variable x = Struct_Type[2];

   x[0] = xfig_plot_new();
   x[0].plot([0,10],[10,0]);
   x[0].xlabel("the x-label");
   x[0].ylabel("the y-label");
   x[0].title("the title");

   x[1] = xfig_plot_new();
   x[1].plot([0,10],[10,0]);
   x[1].axis(; off);

   variable i, fmt=".png";
   _for i (0, length(x)-1, 1)
     {
	variable file = "plot${i}_scaled0"$+fmt;
	vmessage("rendering %s", file);
	x[i].render(path_concat (OutDir, file));

	file = "plot${i}_scaled1"$+fmt;
	vmessage("rendering %s after scaling", file);
	x[i].scale(0.5);
	x[i].render(path_concat(OutDir, file));

	file = "plot${i}_scaled2"$+fmt;
	vmessage("rendering %s after further scaling", file);
	x[i].scale(.5*(1+sqrt(5)), sqrt(5));
	x[i].render(path_concat (OutDir, file));
     }
}
