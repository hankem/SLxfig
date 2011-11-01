require ("xfig");

define slsh_main ()
{
   %
   % position of the eye
   %

   variable distance = 2;  % must be > sqrt(3)/2 to view the cube from the outside
   % small distances lead to strong projective effects
   % large distances lead to a quasi-orthogonal projection
   variable THETA = 57 + [0:359:10];  % array of theta values
   variable PHI = 30;      % (possible) array of  phi  values


   %
   % defining squares in different coordinate planes
   %

   variable c1 = [0, 1, 1, 0, 0] - .5;  % coordinates for axis 1
   variable c2 = [0, 0, 1, 1, 0] - .5;  % coordinates for axis 2
   variable cm = [0, 0, 0, 0, 0] - .5;  % constant (-) coordinates for axis 3
   variable cp = [1, 1, 1, 1, 1] - .5;  % constant (+) coordinates for axis 3

   variable plist = xfig_new_polygon_list();
   % Mind the orientation! Only polygons with normal vector pointing toward the eye will currently be rendered.
   plist.insert ( xfig_new_polygon (vector(c1, c2, cp); fillcolor="#FF0000") );  % normal vector ( 0,  0,  1) => "outwards"
   plist.insert ( xfig_new_polygon (vector(cp, c1, c2); fillcolor="#00EE00") );  % normal vector ( 1,  0,  0) => "outwards"
   plist.insert ( xfig_new_polygon (vector(c2, cp, c1); fillcolor="#0000FF") );  % normal vector ( 0,  1,  0) => "outwards"
   plist.insert ( xfig_new_polygon (vector(c2, c1, cm); fillcolor="#EEEE00") );  % normal vector ( 0,  0, -1) => "outwards"
   plist.insert ( xfig_new_polygon (vector(cm, c2, c1); fillcolor="#00EEEE") );  % normal vector (-1,  0,  0) => "outwards"
   plist.insert ( xfig_new_polygon (vector(c1, cm, c2); fillcolor="#EE00EE") );  % normal vector ( 0, -1,  0) => "outwards"


   %
   % rendering several perspectives and including them into one pdf via LaTeX
   %

   variable render_png = 1;

   variable base = path_basename_sans_extname (__FILE__);
   variable dir = base;
   ()=mkdir (dir);

   variable fp = fopen ("$base.tex"$, "w");
   ()=fprintf (fp, `\documentclass{article}
\usepackage{graphicx}
\usepackage[dvipdfm,paperwidth=10cm,paperheight=10cm,margin=0cm]{geometry}
\setlength{\parindent}{0cm}
\pagestyle{empty}
\begin{document}
`);
   foreach (THETA)
     {
	variable theta = ();
	foreach (PHI)
	  {
	     variable phi = ();
	     xfig_set_eye (distance, theta, phi);
	     if (render_png)
	       {
		  plist.render ("$base.png"$);
		  render_png = 0;
	       }

	     variable ps_filename = path_concat (dir, sprintf ("%03.f_%03.f.ps", theta, phi));
	     plist.render (ps_filename);
	     ()=fprintf (fp, "\\includegraphics[viewport=280 370 330 420,width=\\textwidth]{%s}\n", ps_filename);
	  }
     }
   ()=fprintf (fp, `\end{document}`);
   ()=fclose (fp);
   ()=system ("latex $base.tex; dvipdfm $base.dvi; rm $base.log $base.aux $base.dvi"$);


   %
   % purge tex files
   %

   ()=system ("rm -rf $base.tex $dir/"$);
}
