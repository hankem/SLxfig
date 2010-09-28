require("xfig");

variable dy = 2.5;

variable c = xfig_new_compound();

variable a, txt;
_for a (0, 1, 1)
{
  txt = xfig_new_text(`\centering\tt arrow\_\\style=$a`$);
  xfig_justify_object(txt, vector((a ? dy : -dy), .5, 0), vector(0, -.5, 0));
  c.append(txt);
}

_for a (0, 14, 1)
{
  variable q = struct { arrow_type=a, arrow_style=1, arrow_width=16, arrow_heigth=32 };
  c.append(xfig_new_polyline([-dy,dy], [-a, -a]
			     ; width=2,
			       depth=a,
			       backward_arrow=xfig_create_arrow(; @q, arrow_style=0),
			       forward_arrow =xfig_create_arrow(; @q, arrow_style=1)
			    )
	  );
  txt = xfig_new_text(`\tt arrow\_type=$a`$);
  xfig_justify_object(txt, vector(0, -a, 0), vector(0, -.5, 0));
  c.append(txt);
}

c.render("arrows.eps");
