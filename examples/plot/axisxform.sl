require ("xfig");
require ("rand");

private define wcs_func (x, cd)
{
   variable s = sign(x);
   return s*sqrt(s*x);
}

private define wcs_invfunc (x, cd)
{
   return sign(x)*x*x;
}

xfig_plot_add_transform ("sqrt", &wcs_func, &wcs_invfunc, NULL);

define slsh_main ()
{
   variable n = 100000;
   variable x = rand_gauss (1.0, n);
   x = x[array_sort(x)];
   variable c = cumsum(1+Double_Type[n]);
   c /= c[-1];
   variable w = xfig_plot_new ();
   w.xaxis(;wcs="sqrt",);
   w.yaxis(;wcs="cdf",);	       %  built-in method for CDFs
   w.plot (x, c);
   w.render ("axisxform.png");   
}
