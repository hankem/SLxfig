private variable Magic_Bytes = "\d137\d80\d78\d71\d13\d10\d26\d10";

private define read_exactly_n_bytes (fd, n)
{
   variable buf;
   variable nbytes = read (fd, &buf, n);
   if (nbytes != n)
     verror ("Error reading png file");
   return buf;
}

private define open_png (png)
{
   variable fd = open (png, O_RDONLY);
   if (fd == NULL)
     verror ("Unable to open png file %S", png);
   variable magic = read_exactly_n_bytes (fd, strlen (Magic_Bytes));
   if (magic != Magic_Bytes)
     verror ("%s is not a PNG file", png);
   
   return fd;
}

private define read_4byte_uint (fd)
{
   variable buf = read_exactly_n_bytes (fd, 4);
   return unpack (">K", buf);
}

private define read_png_chunk (fd)
{
   variable length, type, data, crc;

   length = read_4byte_uint (fd);
   type = read_exactly_n_bytes (fd, 4);
   %type = read_4byte_uint (fd);
   data = read_exactly_n_bytes (fd, length);
   crc = read_4byte_uint (fd);
   
   return length, type, data, crc;
}

% The IHDR chunk must appear FIRST. It contains:
% Width:              4 bytes
% Height:             4 bytes
% Bit depth:          1 byte
% Color type:         1 byte
% Compression method: 1 byte
% Filter method:      1 byte
% Interlace method:   1 byte

define xfig_new_png (file)
%!%+
%\function{xfig_new_png}
%\synopsis{Create an object that encapsulates a png image}
%\usage{obj = xfig_new_png(String_Type filename);}
%\qualifiers
%\qualifier{depth}{XFig depth}
%\qualifier{x0}{x-position}{0}
%\qualifier{y0}{y-position}{0}
%\qualifier{z0}{z-position}{0}
%\qualifier{just=[jx,jy]}{justification}{[0,0]}
%\description
%  \sfun{xfig_new_png} reads the image dimensions from the file header
%  and passes them to \sfun{xfig_new_pict}. See its documentation for
%  a detailed description of the qualifiers.
%\seealso{xfig_new_pict}
%!%-
{
   variable fd = open_png (file);
   variable length, type, data, crc;
   (length, type, data, crc) = read_png_chunk (fd);
   if (type != "IHDR")
     verror ("Expecting an IHDR header in %s", file);
   variable width, height;
   
   (width, height) = unpack (">k>k", data);
   
   () = close (fd);

   width *= xfig_get_display_pix_size ();
   height *= xfig_get_display_pix_size ();
   
   return xfig_new_pict (file, width, height;; __qualifiers);
}
