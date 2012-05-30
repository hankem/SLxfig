require ("xfig");
private define get_bbox (obj)
{
   variable x0, x1, y0, y1;
   (x0, x1, y0, y1,,) = obj.get_bbox();
   return x0, x1, y0, y1;
}

define slsh_main ()
{
   variable colors = xfig_get_color_names ();
   variable color, i, n = length(colors);

   variable text, text_objs = Struct_Type[n], min_x, max_x, min_y, max_y;
   _for i (0, n-1, 1)
     {
	color = colors[i];
	variable rgb = xfig_lookup_color_rgb (color);
	variable is_dark = 0;
	loop (3)
	  {
	     is_dark += ((rgb&0xFF) <= 0xC0);
	     rgb = rgb >> 8;
	  }
	if (color == "default") is_dark = 3;
	text_objs[i] = xfig_new_text (color; size="large",
				      color=is_dark>1?"white":"black");
     }

   (min_x, max_x, min_y, max_y)
     = array_map (Double_Type, Double_Type, Double_Type, Double_Type,
		  &get_bbox, text_objs);
   variable dx = max(max_x)-min(min_x), dy = max(max_y)-min(min_y),
     dX = vector(-0.5*dx, -0.5*dy, 0);

   variable vbox_objs = {};
   variable nrows = n/5;
   variable row = 0;
   variable column_objs = {};
   variable obj;
   _for i (0, n-1, 1)
     {
	color = colors[i];
	obj = xfig_new_rectangle (dx, dy);
	obj.set_pen_color (color);
	obj.set_fill_color (color);
	obj.set_area_fill (20);
	obj.translate (dX);
	obj = xfig_new_compound (obj, text_objs[i]);
	list_append (column_objs, obj);
	row++;
	if (row == nrows)
	  {
	     list_append (vbox_objs, xfig_new_vbox_compound (__push_list(column_objs)));
	     column_objs = {};
	     row = 0;
	  }
     }
   if (length (column_objs))
     list_append (vbox_objs, xfig_new_vbox_compound (__push_list(column_objs)));
   obj = xfig_new_hbox_compound (__push_list(vbox_objs));
   obj.render ("colornames.png");
}
