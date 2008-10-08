#!/usr/bin/env slsh

prepend_to_slang_load_path (path_concat (getcwd (), "../../src"));
_traceback = 1;
() = evalfile (path_concat ("./", __argv[1]));

