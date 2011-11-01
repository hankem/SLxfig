() = evalfile (path_concat (path_dirname(__FILE__), "setup.sl"));

define slsh_main ()
{
   variable method, angle, col, tone, fname, e, t;
   variable autoepsdir = xfig_get_autoeps_dir();
   foreach method ([0, 2, 3, 4, 1])
     {
        vmessage ("\ndvi2eps_method=%d", method);
        xfig_set_autoeps_dir ("$autoepsdir/$method"$);
	variable outdir = "$OutDir/$method"$;
	() = mkdir (outdir);
	variable failed=0, passed=0;
	foreach angle ([0, 30, 180/PI])
	  foreach col (["black", "blue", "green", "red"])
	    foreach tone (col=="black" ? [""] : ["4", ""])
	      {
		 fname = sprintf ("rotate%.f-%s%s", angle, col, tone);
		 vmessage ("  trying %s...", fname);
		 try (e)
		   t = xfig_new_text (fname; dvi2eps_method=method, rotate=angle, color=col+tone);
		 catch AnyError:
		   {
		      failed++;
		      vmessage ("  ERROR:%s:%s:%S", __argv[0], fname, e.message);
		      continue;
		   }
		 t.render (path_concat (outdir, fname+".eps"));
		 t.render (path_concat (outdir, fname+".png"));
		 t.render (path_concat (outdir, fname+".pdf"));
		 passed++;
	      }
	if (failed) vmessage ("***%s: Failed: %d/%d", __argv[0], failed, failed+passed);
	vmessage ("Check output files in %s", outdir);
     }
}
