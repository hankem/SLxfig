require ("xfig");

public define slsh_main ()
{
   xfig_add_latex_package ("fontenc[T1]", "yfonts", "marvosym"); %, "mathabx");
   xfig_set_font_style (`\swabfamily`);

   variable p = xfig_plot_new ();
   variable a = exp([-1.5:4:#100]);
   variable P = a^1.5;
   p.world (a, P; xlog, ylog);
   p.world2 (a*1.49598e8, P*365.2425; xlog, ylog);
   p.plot (a, P; line=1);

   variable a_planet = [0.39, 0.72, 1, 1.52,  5.20,  9.54, 19.22,  30.06];
   variable P_planet = [0.24, 0.62, 1, 1.88, 11.86, 29.46, 84.01, 164.8 ];
   variable planet = ["Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"];
   p.plot (a_planet, P_planet; sym="diamond", fill=20);
   variable i;
   _for i (0, 7, 1)
     p.xylabel (a_planet[i]*1.05, P_planet[i],
		"\\Large\\"+planet[i], -0.5, 0.5);

   p.xlabel ("Axis: semimaior [unitas: astronomica]");
   p.ylabel ("Periodus: orbitalis: [annus:]");
   p.x2label ("Axis: semimaior [chiliometrum]");
   p.y2label ("Periodus: orbitalis: [dies:]");
   p.xylabel (.05, .93,
	      `\begin{minipage}{95mm}`
	      +"Sed res: est certissima exactissimaque, quod proportio quae est inter binorum quorumcunque Planetarum tempora periodica, sit praecise sesquialtera proportionis: mediarum distantiarum, id est Orbium ipsorum."
	      +`\end{minipage}`,
	      -0.5, 0.5; world0);
   p.scale(1.5);
   p.render ("font-style.png");
}
