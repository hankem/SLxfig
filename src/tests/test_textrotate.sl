() = evalfile (path_concat (path_dirname(__FILE__), "setup.sl"));

define slsh_main ()
{
   variable angle, col, tone, files={};
   variable failed = 0;
   variable passed = 0;
   foreach angle ([0, 30, 180.0/PI])
     {
	foreach col (["blue", "green", "red"])
	  foreach tone (["4", ""])
	    {
	       variable q = struct { color=col+tone };
	       if (angle!=0) q = struct { @q, rotate=angle };
	       variable fname
		 = sprintf ("rotate%d-%s%s.png", int(angle), col, tone);
	       message("Trying "+fname+"...");
	       variable e;
	       try (e)
		 {
		    variable t = xfig_new_text(fname;; q);
		 }
	       catch AnyError:
		 {
		    failed++;
		    vmessage ("ERROR:%s:%s:%S",__argv[0], fname, e.message);
		    continue;
		 }
	       t.render(path_concat (OutDir, fname));
	       list_append(files, fname);
	       passed++;
	    }
     }
   if (failed) vmessage ("***%s: Failed: %d/%d", __argv[0], failed, failed+passed);
   vmessage ("Check output files in %s", OutDir);
}
