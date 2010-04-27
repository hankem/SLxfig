require ("xfig");

public define slsh_main ()
{
   variable w = xfig_plot_new();
   variable x = [0:10:0.1];
   w.plot(x, x^2);

   % The following two statements will produce a warning. The tic mark label at x=10 will be ignored.
   w.x1axis(; major=[1,2,5,10], ticlabels=["one", "two", "five"       ], minor=[0:10]);  % 4 tic marks <-> 3 tic mark labels
   w.x1axis(; major=[1,2,5   ], ticlabels=["one", "two", "five", "ten"], minor=[0:10]);  % 3 tic marks <-> 4 tic mark labels

   w.x1axis(; major=[1,2,5,10], ticlabels=["one", "two", "five", "ten"], minor=[0:10]);
   w.render("ticlabels.png");
}
