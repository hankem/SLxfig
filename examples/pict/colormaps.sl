require ("png");
require ("xfig");
define slsh_main ()
{
   variable width = 10;
   variable height = 1;

   variable cmaps = png_get_colormap_names ();
   variable list = {};
   variable tmpnames = {};
   foreach (cmaps)
     {
	variable name = ();
	variable cmap = png_get_colormap (name);
	variable tmpname = "tmp-$name.png"$;
	png_write (tmpname, _reshape(cmap, [1, length(cmap)]));
	list_append (tmpnames, tmpname);
	variable png = xfig_new_pict (tmpname, width, height);
	variable label = xfig_new_text ("\\verb|$name|"$; size="Large");
	variable obj = xfig_new_hbox_compound (png, label, 1);
	list_append (list, obj);
     }
   obj = xfig_new_vbox_compound (__push_list(list), 0);
   obj.render ("colormaps.png");

   foreach tmpname (tmpnames)
     () = remove (tmpname);
}
