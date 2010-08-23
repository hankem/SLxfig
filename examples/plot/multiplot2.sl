require ("xfig");

define sin_series(x, n)
{
  variable y = 0*x;
  variable i, sign_and_factorial=1.;
  _for i (0, n, 1)
  {
    y += x^(2*i+1)/sign_and_factorial;
    sign_and_factorial *=  -(2*i+2) * (2*i+3);
  }
  return y;
}

public define slsh_main ()
{
   variable n = 12;
   variable w = Struct_Type[n];
   variable x = [-2*PI:2*PI:#1000];
   variable i;
   _for i (0, n-1, 1)
     {
	w[i] = xfig_plot_new (10, 4);
        w[i].world (-2*PI, 2*PI, -PI,  PI);
	w[i].plot (x, sin_series(x, i));
        w[i].xylabel(0.1, 0.85, "$n="+string(i)+"$"; world0);
     }
   xfig_multiplot (w; cols=3, xlabel="$x$", ylabel="$y$", title="$\displaystyle y_n=\sum_{i=0}^n(-1)^i\frac{x^{2i+1}}{(2i+1)!}$"R
		  ).render ("multiplot2.png");
}
