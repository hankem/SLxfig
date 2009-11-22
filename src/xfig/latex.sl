% -*- mode: slang; mode: fold -*-
% LaTeX and EPS interface

%{{{ Tmpfile and Dir handling Functions 

private variable Latex_Tmp_Dir = NULL;
private variable Latex_Packages = {"amsmath", "bm", "color"};
private variable Latex_Font_Size = 12;
private variable Latex_Default_Color = "black";
private variable Latex_Default_Font_Style = "\bf\boldmath"R; 
private variable Supported_Font_Sizes =
[
   "\\tiny", "\\scriptsize", "\\footnotesize", "\\small", "\\normalsize",
     "\\large","\\Large", "\\LARGE", "\\huge", "\\Huge"
];
   
private variable EPS_Dir = NULL;

private define mkdir_recurse ();
private define mkdir_recurse (dir)
{
   variable topdir = path_dirname (dir);

   if (NULL == stat_file (topdir))
     mkdir_recurse (topdir);
   
   if ((-1 == mkdir (dir, 0777))
       and (errno != EEXIST))
     verror ("Unable to mkdir(%s): %s", dir, errno_string(errno));
}

private define make_tmp_filename (base, ext)
{
   base = sprintf ("%s_%d", base, getpid ());
   variable file = strcat (base, ext);
   variable count = 0;
   
   while (NULL != stat_file (file))
     {
	file = sprintf ("%s_%X%s", base, count, ext);
	count++;
     }
   return file;
}

define xfig_set_tmp_dir (tmp)
{
   mkdir_recurse (tmp);
   Latex_Tmp_Dir = tmp;
}

define xfig_get_tmp_dir ()
{
   if (Latex_Tmp_Dir == NULL)
     xfig_set_tmp_dir (make_tmp_filename ("tmp", ""));

   return Latex_Tmp_Dir;
}

define xfig_make_tmp_file (base, ext)
{
   base = path_concat (xfig_get_tmp_dir (), base);
   return make_tmp_filename (base, ext);
}

define xfig_set_autoeps_dir (dir)
{
   mkdir_recurse (dir);
   EPS_Dir = dir;
}

define xfig_get_autoeps_dir ()
{
   if (EPS_Dir == NULL)
     xfig_set_autoeps_dir ("autoeps");
   
   return EPS_Dir;
}

private define make_autoeps_file (base)
{
   base = path_concat (xfig_get_autoeps_dir (), base);
   return make_tmp_filename (base, ".eps");
}

private define make_tmp_latex_file (base)
{
   base = path_concat (xfig_get_tmp_dir (), base);
   return make_tmp_filename (base, ".tex");
}

%}}}

%{{{ Running LaTeX and dvips 

private variable LaTeX_Pgm = "latex";
private variable Dvips_Pgm = "dvips -E";
  
private define run_cmd (cmd)
{
   if (-1 == system_intr (cmd))
     vmessage ("****WARNING: %s failed\n", cmd);
}

private define run_latex (file)
{
   run_cmd (sprintf ("cd %s; %s %s", 
		     path_dirname (file), LaTeX_Pgm, path_basename (file)));
}

private define run_dvips (dvi, eps)
{
   run_cmd (sprintf ("%s %s -o %s", Dvips_Pgm, dvi, eps));
}


%}}}

define xfig_get_eps_bbox (file)
{
   variable x0, y0, x1, y1;
   variable fp = fopen (file, "r");
   if (fp == NULL)
     verror ("Unable to open %s", file);
   
   variable inside = 0;
   foreach (fp) using ("line")
     {
	variable line = ();
	
	if (line[0] != '%')
	  continue;
	    
	if (0 == strncmp ("%%Begin", line, 7))
	  {
	     inside++;
	     continue;
	  }

	if (0 == strncmp ("%%End", line, 5))
	  {
	     if (inside) inside--;
	     continue;
	  }

	if (inside)
	  continue;

	if (strncmp ("%%BoundingBox:", line, 14))
	  continue;

	if (is_substr (line, "(atend)"))
	  continue;

	line = strchop (line, ':', 0)[1];
	if (4 != sscanf (line, "%f %f %f %f", &x0, &y0, &x1, &y1))
	  break;
	
	return (x0, y0, x1, y1);
     }
   verror ("Bad or no bounding box in EPS file %s", file);
}


private variable Equation_Number = 0;

private define output (fp, s)
{
   if (-1 == fputs (s, fp))
     verror ("Write to latex file failed");
}

private define open_latex_file (file)
{
   variable fp = fopen (file, "w");
   if (fp == NULL)
     verror ("Unable to open %s", file);
   
   return fp;
}

private define check_font_struct (s)
{
   variable f = s.size;
   if (f == NULL)
     f = "\\normalsize";   
   if (f[0] != '\\')
     f = strcat ("\\", f);
   
   if (0 == length (where (f == Supported_Font_Sizes)))
     {
	() = fprintf (stderr, "*** Warning: font size %s not supported\n", f);
	f = "\\normalsize";
     }
   s.size = f;
   
   f = s.color;
   if (f == NULL)
     f = 0;

   if (typeof (f) == String_Type)
     {
	(f,) = strreplace (strlow (f), " ", "", strlen (f));
	f = xfig_lookup_color_rgb (f);
     }
   s.color = f;
   
   f = s.style;
   if (f != NULL)
     {
	if (f[0] != '\\')
	  f = strcat ("\\", f);
#iffalse
	if (0 == length (where (f == Supported_Styles)))
	  {
	     () = fprintf (stderr, "*** Warning: font style %s not supported\n", f);
	     f = NULL;
	  }
#endif
     }
   s.style = f;
}

private define make_font_struct ()
{
   return struct
     {
	color = qualifier ("color",  Latex_Default_Color),
	style = qualifier ("style",  Latex_Default_Font_Style),
	size = qualifier ("size", "\\normalsize"),
     };
}

define xfig_make_font ()
{
   variable s = make_font_struct (;;__qualifiers);
   if (_NARGS == 0)
     return s;
   
   if (_NARGS != 3)
     {
	usage ("font = %s (style, size, color)", _function_name ());
     }
   
   variable style, size, color;
   if (style != NULL) s.style = style;
   if (size != NULL) s.size = size;
   if (color != NULL) s.color = color;

   return s;
}

   
private define make_preamble (font)
{
   variable str;
   str = sprintf ("\\documentclass[%dpt]{article}\n", Latex_Font_Size);
   foreach (Latex_Packages)
     {
	variable package = ();
	str = strcat (str, sprintf ("\\usepackage{%s}\n", package));
     }

   if (font == NULL)
     font = xfig_make_font (NULL, NULL, NULL);
   check_font_struct (font);

   if (font.color != 0)
     {
	variable rgb = font.color;
	variable r = (rgb & 0xFF0000) shr 16;
	variable g = (rgb & 0xFF00) shr 8;
	variable b = (rgb & 0xFF);
	str = sprintf ("%s\\definecolor{defaultcolor}{rgb}{%.3g,%.3g,%.3g}\n",
		       str, r / 255.0, g/255.0, b/255.0);
	str = strcat (str, "\\color{defaultcolor}\n");
     }
   % End of preamble

   str = strcat (str, "\\begin{document}\n\\pagestyle{empty}\n");
   if (font.style != NULL)
     str = strcat (str, font.style, "\n");

   if ((font.size != NULL) && (font.size != "\\normalsize"))
     str = strcat (str, font.size, "\n");

   return str;
}

private define close_latex_file (fp)
{
   output (fp, "\n\\end{document}\n");
   if (-1 == fclose (fp))
     verror ("Error closing latex file");
}

private define make_latex_env (env, envargs, body)
{
   if (env != NULL)
     body = sprintf ("\\begin{%s}%s\n%s\n\\end{%s}", 
		     env, envargs, body, env);
   return body;
}

private define write_latex_file (file, str)
{
   variable fp = open_latex_file (file);
   output (fp, str);
   close_latex_file (fp);
}

private define make_latex_string (env, envargs, text, fontstruct)
{
   variable str = make_preamble (fontstruct);
   return strcat (str, make_latex_env (env, envargs, text));
}

private variable Latex_Cache = NULL;

private define escape_latex_string (str)
{
   return strtrans (str, "\n\t", "\001\002");
}
   
private define add_to_cache (epsfile, escaped_str)
{
   if (NULL == stat_file (epsfile))
     return;

   if (Latex_Cache == NULL)
     Latex_Cache = Assoc_Type[String_Type];

   Latex_Cache[escaped_str] = epsfile;
}

private define open_cache_data (mode)
{
   variable dir = xfig_get_autoeps_dir ();
   variable file = path_concat (dir, "epscache.dat");
   return fopen (file, mode);
}

private define close_cache (fp)
{
   () = fclose (fp);
}

private define load_cache ()
{
   if (Latex_Cache != NULL)
     return;

   variable fp = open_cache_data ("r");
   if (fp == NULL)
     return;

   foreach (fp) using ("line")
     {
	variable line = ();
	line = strtok (line, "\t\n");
	if (length (line) != 2)
	  continue;

	add_to_cache (line[0], line[1]);
     }
   close_cache (fp);
}

private define save_cache ()
{
   if (Latex_Cache == NULL)
     return;
   variable fp = open_cache_data ("w");
   variable k, v;
   foreach k, v (Latex_Cache) using ("keys", "values")
     {
	() = fprintf (fp, "%s\t%s\n", v, k);
     }
   close_cache (fp);
}

private define find_cached_file (str)
{
   load_cache ();

   if (Latex_Cache == NULL)
     return NULL;

   ifnot (assoc_key_exists (Latex_Cache, str))
     return NULL;

   return Latex_Cache[str];
}

private define latex_xxx2eps (env, envargs, xxx, base, fontstruct)
{
   variable str = make_latex_string (env, envargs, xxx, fontstruct);
   variable hash = escape_latex_string (str);
   variable epsfile = find_cached_file (hash);

   if (epsfile != NULL)
     return epsfile;

   variable tex = make_tmp_latex_file (base);
   epsfile = make_autoeps_file (base);

   write_latex_file (tex, str);

   run_latex (tex);
   run_dvips (path_sans_extname (tex) + ".dvi", epsfile);
   
   add_to_cache (epsfile, hash);
   save_cache ();

   return epsfile;
}

private define xfig_text2eps (text, fontstruct)
{
   return latex_xxx2eps (NULL, NULL, text, "text", fontstruct);
}

private define equation_function_env (eq, env, fontstruct)
{
   Equation_Number++;
   variable base = sprintf ("eq_%d", Equation_Number);
   eq += " \\nonumber";
   return latex_xxx2eps (env, "", eq, base, fontstruct);
}

define xfig_eq2eps ()
{
   variable fontstruct = NULL;
   if (_NARGS == 2)
     fontstruct = ();
   if (fontstruct == NULL)
     fontstruct = make_font_struct (;;__qualifiers);

   variable eq = ();
   return equation_function_env (eq, "equation*", fontstruct);
}
define xfig_eqnarray2eps ()
{
   variable fontstruct = NULL;
   if (_NARGS == 2)
     fontstruct = ();
   if (fontstruct == NULL)
     fontstruct = make_font_struct (;;__qualifiers);
   variable eq = ();
   return equation_function_env (eq, "eqnarray*", fontstruct);
}

define xfig_new_eps (file)
{
   variable x0, x1, y0, y1;
   (x0, y0, x1, y1) = xfig_get_eps_bbox (file);
   variable dx = xfig_scale_from_inches ((x1 - x0)/72.0);
   variable dy = xfig_scale_from_inches ((y1 - y0)/72.0);
   return xfig_new_pict (file, dx, dy;; __qualifiers);
}

private define do_xfig_new_xxx (fun, text, fontstruct)
{
   variable eps = (@fun) (text, fontstruct;; __qualifiers);
   return xfig_new_eps (eps;; __qualifiers);
}

define xfig_new_eq (eq)
{
   variable fontstruct = NULL;
   if (_NARGS == 2)
     fontstruct = ();
   if (fontstruct == NULL)
     fontstruct = make_font_struct (;;__qualifiers);
   do_xfig_new_xxx (&xfig_eq2eps, eq, fontstruct;; __qualifiers);
}


%!%+
%\function{xfig_new_text (text [,font_object])}
%\synopsis{Create a text object by running LaTeX}
%\usage{obj = xfig_new_text (String_Type text [,font_object])}
%\description
%  This function runs LaTeX on the specified text string and returns the
%  resulting object.  The text string must be formatted according to the LaTeX
%  rules.  The optional parameter is a structure that may be used to specify
%  the font, color, pointsize, etc to use when calling LaTeX.  This structure
%  may be instantiated using the xfig_font_new.
%\seealso{xfig_font_new}
%!%-
define xfig_new_text ()
{
   variable fontstruct = NULL;
   if (_NARGS == 2)
     fontstruct = ();
   if (fontstruct == NULL)
     fontstruct = make_font_struct (;;__qualifiers);
   variable text = ();
   do_xfig_new_xxx (&xfig_text2eps, text, fontstruct;; __qualifiers);
}

define xfig_set_font_style (style)
{
   Latex_Default_Font_Style = style;
}

define xfig_add_latex_package (package)
{
   list_append (Latex_Packages, package, -1);
}
