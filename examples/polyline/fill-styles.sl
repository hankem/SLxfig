require("xfig");

define slsh_main()
{
  variable x, y, fill, c = xfig_new_compound();
  _for x (0, 9, 1)
    c.append( xfig_new_text(`\_`+string(x); x0=x+.5, y0=1.5) );
  _for y (0, 6, 1)
    c.append( xfig_new_text(string(y)+`\_`; x0=-.5, y0=-y+.5) );
  _for fill (0, 62, 1)
  {
    x =  (fill mod 10) + [0,1,1,0];
    y = -(fill  /  10) + [0,0,1,1];
    variable p = xfig_new_polyline(x, y; closed, areafill=fill, fillcolor=1);
    c.append(p);
  }
  c.render("fill-styles.png");
}
