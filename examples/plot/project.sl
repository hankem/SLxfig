#!/usr/bin/env slsh

() = fprintf (stderr, "This example is a work-in-progress\n");
exit (1);

require ("xfig");

private define project_image (img, X, xhat, yhat, pixel_size)
{
   xfig_set_eye (1000, 60, 0);
   
   variable nx, ny, dims;
   dims = array_shape (img);
   nx = dims[1];
   ny = dims[0];

   variable xll, xlr, xul, xur;
   variable dx = (nx*pixel_size)*xhat;
   variable dy = (ny*pixel_size)*yhat;

   Xll = X - 0.5*dx - 0.5*dy;
   Xlr = X + 0.5*dx - 0.5*dy;
   Xul = X - 0.5*dx + 0.5*dy;
   Xur = X + 0.5*dx + 0.5*dy;

   variable xll, xlr, xul, xur, yll, ylr, yul, yur;
   (xll, yll) = xfig_project_to_xfig_plane (Xll);
   (xlr, ylr) = xfig_project_to_xfig_plane (Xlr);
   (xur, yur) = xfig_project_to_xfig_plane (Xur);
   (xul, yul) = xfig_project_to_xfig_plane (Xul);
   
   variable xmin, ymin, xmax, ymax;
   xmin = min ([xll, xlr, xur, xul]);
   xmax = max ([xll, xlr, xur, xul]);
   ymin = min ([yll, ylr, yur, yul]);
   ymax = max ([yll, ylr, yur, yul]);
   
}
