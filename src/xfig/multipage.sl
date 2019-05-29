require ("process");
% Render a file with multiple pages.  This is accomplished by creating
% a series of intermediate .eps files, and then use gs create the
% final outout file
%
private variable Multipage_Type = struct
{
   add,
   close,
   base, ext,
   save,
   page_files,
   bboxes,
   flags,
};
private variable MP_SAVE = 0x01;
private variable MP_RESCALE = 0x02;
private variable MP_CENTER = 0x04;

%!%+
%\function{xfig_multipage.add}
%\synopsis{Add an xfig object to a multipage file}
%\usage{<multipage_object>.add(ob)}
%\description
% This function is used to render an xfig object to a multipage file.
% This is done by rendering the object to an intermediate .eps file.
% The file will removed upon closing the multipage file.
%\qualifiers
%\qualifier{save}{Keep the intermediate file, do not remove it}
%\qualifier{file=fname}{Use \exmp{fname} as the basename of the
%intermediate file.  The .eps extension will be used.}
%\seealso{xfig_multipage_open, xfig_multipage_close}
%!%-
private define multipage_add ()
{
   if (_NARGS != 2)
     usage (".multipage_add (m, obj; file=filename, save, rescale)");
   variable m, obj;
   (m, obj) = ();

   variable page = length (m.page_files);
   variable file = qualifier ("file", m.base + "_pg$page"$ + ".eps");
   if (path_extname (file) == "")
     file += ".eps";

   obj.render (file);
   list_append (m.page_files, file);
   variable flags = 0;
   if (m.save || qualifier_exists ("save")) flags |= MP_SAVE;
   if (qualifier_exists ("rescale")) flags |= MP_RESCALE;
   list_append (m.flags, flags);
   if (path_extname (file) == ".eps")
     {
        list_append (m.bboxes, [xfig_get_eps_bbox (file)]);
     }
}


%!%+
%\function{xfig_multipage.close}
%\synopsis{Close a multipage file}
%\usage{<multipage_object>.close}
%\description
% This function is used to close a multipage file.   It will invoke
% ghostscript to write the intermediate files to the final document,
% and then remove those intermediate files that were flagged for
% removal.
%\qualifiers
%\qualifier{verbose=value}{If greater than 0, show the ghostscript command line.}
%\qualifier{crop}{If given, crop the resulting multipage file to the
% largest bounding box of intermediate files.}
%\qualifier{margin=value}{When not cropping, add a margins to each
% page of the specified size in inches.  The default is 0.5 inches}
%\seealso{xfig_multipage_open, xfig_multipage.add}
%!%-
define xfig_multipage_close (m)
{
   variable file = m.base + m.ext;
   variable verbose = (qualifier ("verbose", _XFig_Verbose) > 0);
   variable margin = qualifier ("margin", 0.5);
   variable crop = qualifier_exists ("crop");
   variable close_flags = 0;
   if (qualifier_exists ("center")) close_flags |= MP_CENTER;
   if (qualifier_exists ("rescale")) close_flags |= MP_RESCALE;

   variable i, n = length (m.bboxes);
   variable pinfo = xfig_get_paper_size_info ();
   variable psscale = 72.0;       %  points per inch
   variable
     dev_width = pinfo.width*psscale, dev_height = pinfo.height*psscale,
     dev_margin = margin*psscale;

   variable input_files = m.page_files;

   variable bboxes = m.bboxes;
   variable new_input_files = {};
   variable need_bbox_flags = MP_RESCALE|MP_CENTER;
   _for i (0, n-1, 1)
     {
        variable flags = m.flags[i] | close_flags;
        if (flags & need_bbox_flags)
          {
             variable bbox = bboxes[i];
             variable x0 = bbox[0], y0 = bbox[1], x1 = bbox[2], y1 = bbox[3];
             variable dx = double(x1-x0), dy = double(y1-y0), xc = 0.5*(x0+x1), yc = 0.5*(y0+y1);
             variable scale = 1.0, tx = 0.0, ty = 0.0;
             if (flags & MP_RESCALE)
               {
                  variable sx = (dev_width-2*dev_margin)/dx;
                  variable sy = (dev_height-2*dev_margin)/dy;
                  scale = _min(sx,sy);
                  tx = dev_margin - sx*x0;
                  ty = dev_margin - sy*y0;
               }
             if (flags & MP_CENTER)
               {
                  tx = (0.5*dev_width - scale*xc);
                  ty = (0.5*dev_height - scale*yc);
               }
             list_append (new_input_files, "-c");
             list_append (new_input_files, "<</BeginPage{${scale} ${scale} scale ${tx} ${ty} translate}>> setpagedevice"$);
             list_append (new_input_files, "-f");
          }
        list_append (new_input_files, input_files[i]);
     }
   input_files = list_to_array (new_input_files);

   dev_width = nint(dev_width);
   dev_height = nint(dev_height);


   variable argv =
     ["gs", "-q", "-dNOPAUSE", "-dBATCH", "-dSAFER",
      "-dCompatibilityLevel=1.3",
      "-sPAPERSIZE=" + strlow(pinfo.name),
      "-dPDFSETTINGS=/printer",
      %"-dDEVICEWIDTH=$dev_width"$, "-dDEVICEHEIGHT=$dev_height"$,
      "-dPDFFitPage",
      %"-dFIXEDMEDIA",
      crop ? ["-dEPSCrop"] : (),
      "-sDEVICE=pdfwrite",
      "-dSubsetFonts=true",
      "-dEmbedAllFonts=true",
      "-sOutputFile=" + file,
      input_files
     ];
   %argv = ["pdftk", list_to_array(m.page_files), "cat", "output", file];
   variable cmd = strjoin (argv, " ");
   if (verbose)
     message ("$ " + cmd);

   variable s = new_process (argv).wait();
   if ((s.exited == 0) || s.exit_status)
     throw OSError, "Process failed:\n" + cmd;

   _for i (0, n-1, 1)
     {
	ifnot (m.flags[i] & MP_SAVE) () = remove (m.page_files[i]);
     }
}


%!%+
%\function{xfig_multipage_open}
%\synopsis{Create an xfig multipage file}
%\usage{m = xfig_multipage_open (String_Type file [;qualifiers])}
%\description
% This function will create a new multipage file.  Xfig objects may
% be written to the multipage file using the .add method.  Each call
% to the .add method will result in the object being rendered to an
% intermediate eps file. When finished, the .close method must be used to
% produce the final file and remove the intermediate files.
%
% The \exmp{file} parameter is used to specify the name of the
% multipage file.  Only multipage pdf files are supported; hence, the
% filename extension must be \exmp{.pdf}.
%\qualifiers
%\qualifier{save}{Do not remove the intermediate files}
%\example
%   m = xfig_multipage_open ("example.pdf");
%   w = xfig_plot_new ();
%   % Code create the first plot
%   m.add (w);
%   w = xfig_plot_new ();
%   % Code to create the second plot
%   m.add (w);
%   m.close ();
%\seealso{xfig_multipage.close, xfig_multipage.add}
%!%-
define xfig_multipage_open ()
{
   if (_NARGS != 1)
     {
	usage ("\n\
m = xfig_multipage_open (file; save)\n\
m.add (obj; file=name, save)\n\
m.close()\n\
Note: The save qualifier means that the intermediate file will be saved.\n\
      Intermediate filenames will created with the basename suffixes _pgN\n\
"
	      );
     }
   variable file = ();
   variable m = @Multipage_Type;
   m.add = &multipage_add;
   m.close = &xfig_multipage_close;

   m.base = path_sans_extname (file);
   m.ext = path_extname (file);
   if (m.ext == "") m.ext = ".pdf";
   if (m.ext != ".pdf")
     throw NotImplementedError, "Only a multipage .pdf files are supported";

   m.save = qualifier_exists("save");
   m.page_files = {};
   m.flags = {};
   m.bboxes = {};
   m.close = &xfig_multipage_close;
   return m;
}
