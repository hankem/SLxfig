require ("xfig");

public define slsh_main ()
{
	variable w = xfig_plot_new ();
	w.world (.1, 10, .1, 10; xlog, ylog);
	w.yaxis (; format="%.1f", ticlabels2=0);
	w.xaxis (; major=[.1, .2, .5, 1, 2, 5, 10], minor=[[.1:1:#10], [1:10:#10]], ticlabels2=0);

	variable x = 10^[-1:1:#100];
	w.plot (x,    x^ .2 + x^ 5 );
	w.plot (x, 1/(x^-.2 + x^-5));
	w.render ("fixed_format.png");
}
