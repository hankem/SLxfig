require ("xfig");

public define slsh_main ()
{
   variable t0 = 1546300800 + 5*3600;
   variable tmax = t0 + 1.2*86400;
   variable tmin = t0 - 1.2*86400;
   variable tinfo = xfig_timetics (tmin, tmax; localtime, maxtics=6);
   variable t = [tmin:tmax:#1024];
   variable y = sin(2*PI/(1*86400)*(t-tmin));   % 1 day period
   variable w = xfig_plot_new(20,15);
   w.plot (t, y; color="blue");
   w.x1axis (;; tinfo); %major=tinfo.major, minor=tinfo.minor, ticlabels=tinfo.ticlabels);
   w.ylabel ("Value");
   w.xlabel ("Time");
   w.render ("timetics.png");
}
