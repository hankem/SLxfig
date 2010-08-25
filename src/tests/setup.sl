#!/usr/bin/env slsh
require ("rand");

if (__argc != 2)
{
   () = fprintf (stderr, "Usage: slsh %s OUTPUTDIR\n", __argv[0]);
   () = fprintf (stderr, "\
OUTPUTDIR may contain:\n\
  $uid        expands to userid\n\
  $pid        expands to process-id\n\
  $ppid       expands to parent process-id\n\
  $time       expands to the integer Unix time\n\
  $rnd        expands to a random integer\n");
   exit (1);
}

vmessage ("Running %s", __argv[0]);

private variable RootDir;
private define set_root_dir (dir)
{
   variable uid = getuid ();
   variable time = _time ();
   variable rnd = rand ();
   variable pid = getpid ();
   variable ppid = getppid ();
   RootDir = _$(dir);
}
set_root_dir (__argv[1]);

variable TestDir = path_dirname (__FILE__);
prepend_to_slang_load_path (path_concat (TestDir, ".."));

require ("xfig");

xfig_set_verbose (-1);
xfig_set_tmp_dir (path_concat (RootDir, "tmp"));
xfig_set_autoeps_dir (path_concat(RootDir, "autoeps"));
variable OutDir = path_concat (RootDir, "output");
() = mkdir (OutDir);
