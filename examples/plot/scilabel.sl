require ("xfig");

define slsh_main ()
{
   xfig_plot_set_default_size (10,10);
   variable x, y, w1, w2, w3, w4, w5, w6;
   w1 = xfig_plot_new ();
   x = [1e-6:1.1e-5:#100],
   w1.plot (x,x);

   w2 = xfig_plot_new ();
   x = [1e-6:1.1e-5:#100],
   w2.plot (x,x;logy);

   w3 = xfig_plot_new ();
   x = [1e7:1.1e9:#100],
   w3.plot (x,x;logy);

   w4 = xfig_plot_new ();
   x = [9e7:1.1e20:#100];
   w4.plot (x,x;logy);

   w5 = xfig_plot_new ();
   x = [3e7:8e7:#100];
   w5.plot (x,x;logy);

   w6 = xfig_plot_new ();
   x = [4e-2:6e1:#100];
   y = [4e-7:4e27:#100];
   w6.plot (x,y;loglog);

   xfig_new_vbox_compound (xfig_new_hbox_compound(w1,w2,w3,1),
			   xfig_new_hbox_compound(w4,w5,w6,1),
			   1).render ("scilabel.png");
}

