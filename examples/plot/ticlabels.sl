require ("xfig");

public define slsh_main ()
{
   variable i;
   _for i (1, 4, 1)
     {
       variable w = xfig_plot_new();
       variable x = [0:10:0.1];
       w.plot(x, x^2);

       switch(i)
       { case 1:
           message("The following statement will produce the warning"
                  +` "4 major ticmarks / 3 ticlabels":`);
           w.x1axis(; major=[              1,      2,      5,       10    ],
                  ticlabels=[              "one?", "two?", "five?"        ],
                      minor=[0:10]);
       }
       { case 2:
           message("The following statement will produce the warning"
                  +` "3 major ticmarks / 4 ticlabels":`);
           w.x1axis(; major=[              1,      2,      5              ],
                  ticlabels=[              "one?", "two?", "five?", "ten?"],
                      minor=[0:10]);
       }
       { case 3:
           % The major and ticlabels qualifiers
           % should be used in the following way:
           w.x1axis(; major=[              1,      2,      5,       10    ],
                  ticlabels=[              "one!", "two!", "five!", "ten!"],
                      minor=[0:10]);
       }
       { case 4:
           % The following statement will work correctly:
           % both user_specified_major_tic -1
           %  and user_specified_tic_label "minus one!" will be ignored.
           w.x1axis(; major=[-1,           1,      2,      5,       10    ],
                  ticlabels=["minus one!", "one!", "two!", "five!", "ten!"],
                      minor=[0:10]);
       }

       w.render("ticlabels.png");
     }
}
