#!/usr/bin/env slsh

prepend_to_slang_load_path (path_concat (getcwd (), "../../src"));
require ("xfig");
%sldb ("xfig");
_traceback = 1;

private define main ()
{
   if (__argc != 2)
     {
	() = fprintf (stderr, "Usage: ./%s <example.sl>\n", 
		      path_basename (__argv[0]));
	exit (1);
     }
   () = evalfile (path_concat ("./", __argv[1]));
}

main ();
if (is_defined ("slsh_main"))
  slsh_main ();


