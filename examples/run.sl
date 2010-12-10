#!/usr/bin/env slsh
_traceback=1;
prepend_to_slang_load_path (path_concat (getcwd (), "../../src"));

require ("xfig");

xfig_set_tmp_dir (sprintf ("/tmp/slxfig-%d", getuid()));

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
